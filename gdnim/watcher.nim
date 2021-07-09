import gdnim
import godotapi / [node, resource_loader, resource_saver, directory,
  canvas_layer, v_box_container, line_edit, theme]
import os, strformat, times
import tables, sets, hashes, sequtils

#[
Watcher monitors the dll files for component changes.
If the safe dll is newer than the hot (live) dll, then pack the component instances
into a temporary scene and unload the nodes to free the resource references.
Components need to register with the Watcher, so they can be reloaded.
During a reload phase, the components data can be save and restored upon reload.
]#

const ReloadScenePath = "user://gdnim_hot_reload.tscn"

func safeDllPath(compName: string): string =
  &"{baseDllDir}/{dllPrefix}{compName}_safe.{dllExt}"
func hotDllPath(compName: string): string =
  &"{baseDllDir}/{dllPrefix}{compname}.{dllExt}"

type
  InstanceId = distinct int64

  InstanceData = ref object
    compName: string
    id: InstanceId
    instancePath: string
    parentPath: string
    customData: Variant # seq[byte]
    positionInParent: int64

  ComponentMeta = object
    resourcePath: string

  ReloadNotification = ref object
    elapsedTime: float
    gdLine: LineEdit

proc inc(x: var InstanceId, y = 1) {.borrow.}
proc `==`(x, y: InstanceId): bool {.borrow.}
proc `$`(x: InstanceId): string {.borrow.}

gdobj Watcher of CanvasLayer:

  signal reloading_start(compName: string)
  signal reloading_complete(compName: string)
  signal reloading_error(compName: string, error_msg: string)
  signal instance_unloaded(nodePath: string)
  signal instance_loaded(nodePath: string)

  # data for components and instances
  var compMetaTable: Table[string, ComponentMeta]
  var instancesByCompNameTable: Table[string, seq[InstanceData]]
  var NextInstanceId: InstanceID = InstanceID(0)
  var instanceByIDTable: Table[InstanceId, InstanceData]
  var dependencies: Table[string, HashSet[string]] # if A instances B, then dependencies["A"].contains "B"
  var rdependencies: Table[string, HashSet[string]] # and rdependencies["B"].contains "A"

  # reloading vars
  var enableWatch {.gdExport.}: bool = true
  var watchIntervalSeconds {.gdExport.}: float = 0.3
  var reloadIntervalSeconds {.gdExport.}: float = 0.3
  var watchElapsedSeconds: float
  var reloadElapsedSeconds: float
  var startReloadingCompName: string
  var reloadingComps: seq[string]
  var hasFailedReloading: bool

  # notifications
  var enableNotifications {.gdExport.}: bool = true
  var notification_duration {.gdExport.}: float = 10.0
  var notification_time_to_fade {.gdExport.}: float = 2.0
  var notifications: seq[ReloadNotification]
  var lineEditPacked: PackedScene
  var vbox: VBoxContainer



  proc getSaveOrder(compName: string): seq[string] =
    if not self.dependencies.hasKey(compName):
      result.add compName
      return
    for c in self.dependencies[compName]:
      result.add self.getSaveOrder(c)
    result.add compName

  proc setOwner(owner: Node, n: Node) =
    # if we don't check for filename, we'll get duplicates in the PackedScene
    if not (n == owner) and n.filename.len > 0:
      n.owner = owner

    #print &"set owner {n.name} {n.filename} "
    for i in 0..<n.getChildCount:
      self.setOwner(owner, n.getChild(i))

  proc packScenes() =

    # self.reloadingComps points to all components that are affected by reloading, this is set by saveInstanceData()
    # for each instance, get the path as key, store the node
    # merge the paths if they are on the same branch
    # create a new node and move each of the branches to it
    # set the owner of the nodes
    # pack the new node, and free

    var pathToInstancesTable: Table[string, seq[Node]]
    for compName in self.reloadingComps:
      var compInstancesData = self.instancesByCompNameTable[compName]
      for instData in compInstancesData:
        var n = self.getNode(instData.instancePath)
        var path = $n.getPath()
        if pathToInstancesTable.hasKey(path):
          pathToInstancesTable[path].add n
        else:
          pathToInstancesTable[path] = @[n]

    # pare down branches
    var paths = toSeq(pathToInstancesTable.keys)
    for i in 0..<paths.len:
      var ni_is_child = false
      var ni = self.getNode(paths[i])
      for j in 0..<paths.len:
        if i == j: continue
        var nj = self.getNode(paths[j])
        if nj.isAParentOf(ni):
          ni_is_child = true
          break
      if ni_is_child:
        pathToInstancesTable.del(paths[i])

    # create a new node to contain the instances for packing
    var reloadRoot = gdnew[Node]()
    for path, children in pathToInstancesTable:
      for instance in children:
        instance.getParent().removeChild(instance)
        reloadRoot.addChild instance

    self.setOwner(reloadRoot, reloadRoot)

    var reloadScene = gdnew[PackedScene]()
    if Error.OK == reloadScene.pack(reloadRoot):
      var d = gdnew[Directory]()
      if d.fileExists(ReloadScenePath):
        discard d.remove(ReloadScenePath)

      if Error.OK == resource_saver.save(ReloadScenePath, reloadScene):
        #printWarning &"Watcher: Saved state to {ReloadScenePath}"
        reloadRoot.queue_free()
      else:
        raise newException(Defect, &"Watcher: Failed to save state to {ReloadScenePath}")
    else:
      raise newException(Defect, &"Watcher: Failed to pack state for reload")

  proc unpackScenes() =
    #printWarning &"Watcher: Unpacking hot reload state"
    var reloadInstance = (resource_loader.load(ReloadScenePath) as PackedScene).instance()
    var children = reloadInstance.getChildren()
    for vn in children:
      var n = vn.asObject(Node)
      reloadInstance.removeChild(n)
      var instId = InstanceId(n.get_meta(HotMetaInstanceId).asInt())
      var parentNode = self.get_node(self.instanceByIdTable[instId].parentPath)
      parentNode.addChild(n)
    reloadInstance.queue_free()

  method init() =
    self.lineEditPacked = resource_loader.load(&"res://{baseTscnDir}/watcher_lineedit.tscn") as PackedScene
    self.pause_mode = PAUSE_MODE_PROCESS

  method enter_tree() =
    self.vbox = self.get_node("VBoxContainer") as VBoxContainer
    discard self.getTree().connect("node_removed", self, "unregister_instance")

  method exit_tree() =
    self.lineEditPacked = nil
    self.vbox = nil

  proc fadeNotifications(delta: float64) =
    for i in countDown(self.notifications.len-1, 0):
      var n = self.notifications[i]
      n.elapsedTime += delta
      if n.elapsedTime > self.notification_time_to_fade:
        var alpha = lerp(1.0, 0.0, (n.elapsedTime - self.notification_time_to_fade)/(self.notification_duration - self.notification_time_to_fade))
        n.gdLine.modulate = initColor(1.0, 1.0, 1.0, alpha)

      if n.elapsedTime > self.notification_duration:
        n.gdLine.queue_free()
        n.gdLine = nil
        self.notifications.del i

  proc saveInstanceData(compName: string) =
    if self.reloadingComps.contains(compName):
      return
    self.reloadingComps.add(compName)

    var instancesData = self.instancesByCompNameTable[compName]
    for instData in instancesData:
      try:
        #printWarning &"saving {instData.instancePath}"
        var node = self.get_node(instData.instancePath)
        instData.customData = node.call(HotUnload)
        toV self.emit_signal(WatcherInstanceUnloaded, [instData.instancePath])
      except CallError as e:
        printError &"Watcher reloading: {compName}, Error '{e.err.error}'. From {compName} @ {instData.instancePath}"
        raise

    if self.dependencies.hasKey(compName):
      for dep in self.dependencies[compName]:
        self.saveInstanceData(dep)

    if self.rdependencies.hasKey(compName):
      for rdep in self.rdependencies[compName]:
        self.saveInstanceData(rdep)

  method process(delta: float64) =
    if not self.enableWatch: return
    if self.hasFailedReloading: return

    self.fadeNotifications(delta)

    if self.startReloadingCompName != "":
      if self.reloadElapsedSeconds < self.reloadIntervalSeconds:
        self.reloadElapsedSeconds += delta
        return
      self.reloadElapsedSeconds = 0.0

      var compName = self.startReloadingCompName
      var cmeta = self.compMetaTable[compName]
      if not resource_loader.has_cached(cmeta.resourcePath):
        try:
          moveFile(compName.safeDllPath, compName.hotDllPath)
        except:
          self.hasFailedReloading = true
          var errorMsg = &"!!! Could not moveFile {compName.safeDllPath} to {compName.hotDllPath}"
          self.notify(errorMsg)
          tov self.emitSignal(WatcherReloadingFailed, [compName, errorMsg])
      else:
        self.hasFailedReloading = true
        var errorMsg = &"Watcher: {compName} still cached"
        self.notify(errorMsg)
        tov self.emitSignal(WatcherReloadingFailed, [compName, errorMsg])


      self.get_tree().paused = false
      self.unpackScenes()
      self.notify(&"Watcher: reload complete")
      toV self.emitSignal(WatcherReloadingComplete, [self.startReloadingCompName])

      self.startReloadingCompName = ""
      self.reloadingComps.setLen(0)
      return

    #check for new dlls
    self.watchElapsedSeconds += delta
    if self.watchElapsedSeconds > self.watchIntervalSeconds:
      self.watchElapsedSeconds = 0.0

      for compName in self.compMetaTable.keys:
        if (not (compName in self.reloadingComps)) and fileExists(compName.safeDllPath) and
          getLastModificationTime(compName.safeDllPath) > getLastModificationTime(compName.hotDllPath) and
          getFileSize(compName.safeDllPath) > 0:
          self.notify(&"Watcher: Reloading for {compName}")
          toV self.emitSignal(WatcherReloadingStart, [compName])
          self.get_tree().paused = true
          self.startReloadingCompName = compName
          self.saveInstanceData(compName)
          self.packScenes()
          break

  # registers the instance and its component for Watcher monitoring
  proc register_instance(compName: string, instancePath: string, parentPath: string): seq[byte] {.gdExport.} =
    if not fileExists(compName.hotDllPath):
      printError &"Watcher failed to register {compName}. No dll with this name."
      raise newException(Defect, &"Watcher failed to register {compName}. No dll with this name.")

    if not self.compMetaTable.hasKey(compName):
      #self.notify(wncRegisterComp, &"Watcher registering {compName}")
      var scenePath = findScene(compName)
      self.compMetaTable[compName] = ComponentMeta(resourcePath: scenePath)
      self.instancesByCompNameTable[compName] = @[]

    var instNode = self.get_node(instancePath)
    var instData: InstanceData
    var instID: InstanceId
    if not instNode.has_meta(HotMetaInstanceId):
      # first instance
      instData = new(InstanceData)
      inc self.NextInstanceId
      instID = self.NextInstanceId
      instData.id = instID
      instNode.set_meta(HotMetaInstanceId, int64(instID).toVariant)
      instData.compName = compName
      instData.instancePath = instancePath
      instData.parentPath = parentPath

      #printWarning &"new {compName} instance with id {instID}"
      self.instanceByIDTable[instID] = instData
      self.instancesByCompNameTable[compName].add instData
    else:
      # reloaded
      instID = InstanceId(instNode.get_meta(HotMetaInstanceId).asInt())
      #printWarning &"reloaded {instID} @ {instancePath}"
      instData = self.instanceByIDTable[instID]
      instData.instancePath = instancePath
      discard result.fromVariant(instData.customData)

    toV self.emit_signal(WatcherInstanceLoaded, [instData.instancePath])

  # register direct dependencies of comp
  proc register_dependencies(compName: string, dependencies: seq[string]) {.gdExport.} =
    if not self.dependencies.hasKey(compName):
      self.dependencies[compName] = initHashSet[string]()
    for d in dependencies:
      self.dependencies[compName].incl(d)
      if not self.rdependencies.hasKey(d):
        self.rdependencies[d] = initHashSet[string]()
      self.rdependencies[d].incl(compName)

  # unregister comp instances that are not reloading
  proc unregister_instance(instNode: Node) {.gdExport.} =
    if instNode.has_meta(HotMetaInstanceId):
      var instID = InstanceId(instNode.get_meta(HotMetaInstanceId).asInt())
      var instData = self.instanceByIDTable[instID]
      if not (instData.compName in self.reloadingComps):
        #printWarning &"unregister {instData.id = } @ {instData.instancePath = }"
        self.instanceByIDTable.del(instID)
        let index = self.instancesByCompNameTable[instData.compName].find(instData)
        self.instancesByCompNameTable[instData.compName].del(index)
      #[
      else:
        printWarning &"unregisterInstance: reloading {instData.compName} {instData.id = }"
      ]#

  proc notify(msg: string) =
    if not self.enableNotifications: return
    printWarning &"{msg}"

    var n = ReloadNotification(gdLine: self.lineEditPacked.instance() as LineEdit)
    self.notifications.add n
    n.gdLine.text = msg
    if self.vbox != nil:
      self.vbox.call_deferred("add_child", n.gdLine.toVariant)