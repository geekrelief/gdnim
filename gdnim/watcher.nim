import gdnim
import godotapi / [node, resource_loader, packed_scene, v_box_container, line_edit, scene_tree, theme]
import os, strformat, times
from sequtils import keepItIf
import tables, sets, hashes

#[
Watcher monitors the dll files for component changes.
If the safe dll is newer than the hot (live) dll, then destroy all references
to the resource that uses the dll and reload the resource.
Components need to register with the Watcher, so they can be reloaded.
During a reload phase, the components data can be save and restored upon reload.
]#
const dllDir {.strdefine.}:string = "_dlls"
const dllPrefix = when hostOS == "linux": "lib"
                else: ""
const dllExt = when hostOS == "windows": "dll"
             elif hostOS == "linux": "so"
             elif hostOS == "macosx": "dylib"
             else: "unknown"

const META_INSTANCE_ID = "hot_meta_instance_id" #track instances
const UNLOAD_PROCNAME = "hot_unload"
const DEPENDENCY_RELOAD_PROCNAME = "hot_depreload"
const ADD_CHILD = "add_child"

func safeDllPath(compName:string):string =
  &"{dllDir}/{dllPrefix}{compName}_safe.{dllExt}"
func hotDllPath(compName:string):string =
  &"{dllDir}/{dllPrefix}{compname}.{dllExt}"

gdobj WatcherUnregisterHelper of Reference:
  # helper to store callback on node tree_exited
  # to unregister component instances from Watcher
  var callback*:proc () {.closure, gcsafe.}
  proc onExit() {.gdExport.} =
    self.callback()

type
  InstanceID = distinct int64

  InstanceData = ref object
    compName:string
    id:InstanceID
    saverPath:string
    loaderPath:string
    data:seq[byte]
    helper:WatcherUnRegisterHelper

  ComponentMeta = object
    resourcePath:string
    saverProc:string
    loaderProc:string

  ReloadNotification = ref object
    elapsedTime:float
    gdLine:LineEdit

proc inc(x:var InstanceID, y = 1) {.borrow.}
proc `==`(x, y: InstanceID):bool {.borrow.}
proc `$`(x:InstanceID):string {.borrow.}

func lerp(a, b, t:float32):float32 =
  (b - a ) * t + a


when defined(does_reload):
  gdobj Watcher of Control:

    signal notice(code:int, msg:string)

    var enableWatch {.gdExport.}:bool = true
    var watchIntervalSeconds {.gdExport.}:float = 0.3
    var reloadIntervalSeconds {.gdExport.}:float = 0.3
    var watchElapsedSeconds:float
    var reloadElapsedSeconds:float

    var compMetaTable:Table[string, ComponentMeta]
    var NextInstanceID:InstanceID = InstanceID(0)
    var instancesByCompNameTable:Table[string, seq[InstanceData]]
    var instanceByIDTable:Table[InstanceID, InstanceData]
    var dependencies:Table[string, HashSet[string]] # if A instances B, then dependencies["A"].contains "B"
    var rdependencies:Table[string, HashSet[string]] # and rdependencies["B"].contains "A"
    var reloadingComps:seq[string]

    var enableNotifications {.gdExport.}:bool = true
    var notification_duration {.gdExport.}:float  = 10.0
    var notification_time_to_fade {.gdExport.}:float = 2.0

    var notifications:seq[ReloadNotification]

    var lineEditPacked:PackedScene
    var vbox:VBoxContainer

    proc getSaveOrder(compName:string):seq[string] =
      if not self.dependencies.hasKey(compName):
        result.add compName
        return
      for c in self.dependencies[compName]:
        result.add self.getSaveOrder(c)
      result.add compName

    method init() =
      self.lineEditPacked = resource_loader.load("res://_tscn/watcher_lineedit.tscn") as PackedScene
      self.pause_mode = PAUSE_MODE_PROCESS

    method enter_tree() =
      self.vbox = self.get_node("VBoxContainer") as VBoxContainer

    method exit_tree() =
      self.lineEditPacked = nil
      self.vbox = nil

    method process(delta: float64) =
      if not self.enableWatch: return

      # fade out notifications
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

      # reload comp dlls and reinstantiate instances
      if self.reloadingComps.len > 0:
        if self.reloadElapsedSeconds < self.reloadIntervalSeconds:
          self.reloadElapsedSeconds += delta
          return
        self.reloadElapsedSeconds = 0.0

        var finReloadingComps:seq[string]

        for compName in self.reloadingComps:
          var cmeta = self.compMetaTable[compName]
          if not resource_loader.has_cached(cmeta.resourcePath):
            try:
              moveFile(compName.safeDllPath, compName.hotDllPath)
            except:
              printError &"!!! Could not moveFile {compName.safeDllPath} to {compName.hotDllPath}"

            #reload the scene instances
            var pscene = resource_loader.load(cmeta.resourcePath) as PackedScene
            var instancesData = self.instancesByCompNameTable[compName]
            for instData in instancesData:
              try:
                var loaderNode = self.get_node(instData.loaderPath)
                var instNode = pscene.instance()
                instNode.set_meta(META_INSTANCE_ID, int64(instData.id).toVariant())
                loaderNode.call_deferred(ADD_CHILD, instNode.toVariant())
              except:
                printError &"!!! Could not reinstance \"{instData.saverPath }\" @ \"{instData.loaderPath}\""

            if self.rdependencies.hasKey(compName):
              for rdcompName in self.rdependencies[compName]:
                for rinstData in self.instancesByCompNameTable[rdcompName]:
                  var rnode = self.get_node(rinstData.saverPath)
                  rnode.call_deferred(DEPENDENCY_RELOAD_PROCNAME, compName.toVariant, false.toVariant)

            finReloadingComps.add(compName)
          else:
            printError &"Watcher: {compName} still cached"

        self.reloadingComps.keepItIf(not (it in finReloadingComps))

        self.get_tree().paused = false
        self.notify(RELOADED, &"Watcher reload complete")
        return

      #check for new dlls
      self.watchElapsedSeconds += delta
      if self.watchElapsedSeconds > self.watchIntervalSeconds:
        self.watchElapsedSeconds = 0.0

        for compName in self.compMetaTable.keys:
          if (not (compName in self.reloadingComps)) and fileExists(compName.safeDllPath) and
            getLastModificationTime(compName.safeDllPath) > getLastModificationTime(compName.hotDllPath) and
            getFileSize(compName.safeDllPath) > 0:
            self.get_tree().paused = true
            self.notify(UNLOADING, &"Watcher unloading: {compName}")
            self.reloadingComps.add(compName)

            var cmeta = self.compMetaTable[compName]
            var instancesData = self.instancesByCompNameTable[compName]
            for instData in instancesData:
              try:
                #printWarning &"saving {instData.saverPath}"
                var node = self.get_node(instData.saverPath)
                var saveData:seq[byte]
                discard saveData.fromVariant(node.call(cmeta.saverProc))
                instData.data = move(saveData)
              except CallError as e:
                printError &"Watcher reloading: {compName}, Error '{e.err.error}'. From {compName}.{cmeta.saverProc} @ {instData.saverPath}"
                raise
            if self.rdependencies.hasKey(compName):
              for rdep in self.rdependencies[compName]:
                for rinstData in self.instancesByCompNameTable[rdep]:
                  var node = self.get_node(rinstData.saverPath)
                  discard node.call(DEPENDENCY_RELOAD_PROCNAME, compName.toVariant, true.toVariant)

    # registers the instance and its component for Watcher monitoring
    proc register_instance(compName:string, saverPath:string, loaderPath:string, saverProc=UNLOAD_PROCNAME, loaderProc=ADD_CHILD):seq[byte] {.gdExport.} =
      if not fileExists(compName.hotDllPath):
        printError &"Watcher failed to register {compName}. No dll with this name."
        return
      try:
        if not self.compMetaTable.hasKey(compName):
          self.notify(REGISTER_COMP, &"Watcher registering {compName}")
          self.compMetaTable[compName] = ComponentMeta(resourcePath: findScene(compName), saverProc: saverProc, loaderProc: loaderProc)
          self.instancesByCompNameTable[compName] = @[]

        var instNode = self.get_node(saverPath)
        var instData:InstanceData
        var instID:InstanceID
        if not instNode.has_meta(META_INSTANCE_ID):
          # first instance
          instData = new(InstanceData)
          inc self.NextInstanceID
          instID = self.NextInstanceID
          instData.id = instID
          instNode.set_meta(META_INSTANCE_ID, int64(instID).toVariant)
          instData.compName = compName
          instData.saverPath = saverPath
          instData.loaderPath = loaderPath

          self.instanceByIDTable[instID] = instData
          self.instancesByCompNameTable[compName].add instData
        else:
          # reloaded
          instID = InstanceID(instNode.get_meta(META_INSTANCE_ID).asInt())
          #printWarning &"reloaded {instID} @ {saverPath}"
          instData = self.instanceByIDTable[instID]
          instData.saverPath = saverPath
          result = instData.data
          instData.data.setLen(0)

        proc callback() =
          self.unregisterInstance(instID)
        instData.helper = gdnew[WatcherUnregisterHelper]()
        instData.helper.callback = callback
        discard instNode.connect("tree_exiting", instData.helper, "on_exit")

      except IOError as e:
        printError e.msg

    # register direct dependencies of comp
    proc register_dependencies(compName:string, dependencies:seq[string]) {.gdExport.} =
      if not self.dependencies.hasKey(compName):
        self.dependencies[compName] = initHashSet[string]()
      for d in dependencies:
        self.dependencies[compName].incl(d)
        if not self.rdependencies.hasKey(d):
          self.rdependencies[d] = initHashSet[string]()
        self.rdependencies[d].incl(compName)

    # unregister comp instances that are not reloading
    proc unregisterInstance(instID:InstanceID) =
      var instData = self.instanceByIDTable[instID]
      if not (instData.compName in self.reloadingComps):
        #printWarning &"unregister {instData.id = } @ {instData.saverPath = }"
        self.instanceByIDTable.del(instID)
        let index = self.instancesByCompNameTable[instData.compName].find(instData)
        self.instancesByCompNameTable[instData.compName].del(index)

    proc notify(code:WatcherNoticeCode, msg:string) =
      printWarning &"{msg}"

      var n = ReloadNotification(gdLine: self.lineEditPacked.instance() as LineEdit)
      self.notifications.add(n)
      n.gdLine.text = msg
      if self.vbox != nil:
        self.vbox.call_deferred(ADD_CHILD, n.gdLine.toVariant)
      self.emit_signal("notice", int(code).toVariant, msg.toVariant)

else:
  gdobj Watcher of Control:
    var enableWatch {.gdExport.}:bool = true
    var watchIntervalSeconds {.gdExport.}:float = 0.3
    var reloadIntervalSeconds {.gdExport.}:float = 0.3

    var enableNotifications {.gdExport.}:bool = true
    var notification_duration {.gdExport.}:float  = 10.0
    var notification_time_to_fade {.gdExport.}:float = 2.0
    proc register_dependencies(compName:string, dependencies:seq[string]) {.gdExport.} = discard
    proc register_instance(compName:string, saverPath:string, loaderPath:string, saverProc=UNLOAD_PROCNAME, loaderProc=ADD_CHILD):seq[byte] {.gdExport.} = discard