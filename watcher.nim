import godot
import godotapi / [node, resource_loader, packed_scene, v_box_container, line_edit, scene_tree, theme]
import os, strformat, times, streams
from sequtils import filterIt
import tables, sets
import hot
import math

#[
Watcher monitors the dll files for component changes.
If the safe dll is newer than the hot (live) dll, then destroy all references
to the resource that uses the dll and reload the resource.
Components need to register with the Watcher, so they can be reloaded.
During a reload phase, the components data can be save and restored upon reload.
]#
const dllDir {.strdefine.}:string = "_dlls"

func safeDllPath(compName:string):string =
  &"{dllDir}/{compName}_safe.dll"
func hotDllPath(compName:string):string =
  &"{dllDir}/{compname}.dll"

type
  ReloadMeta = object
    compName:string
    saverPath:string
    loaderPath:string
    saverProc:string
    loaderProc:string
    resourcePath:string

  ReloadNotification = ref object
    elapsedTime:float
    gdLine:LineEdit

func lerp(a, b, t:float32):float32 =
  (b - a ) * t + a

gdobj Watcher of Control:

  var enableWatch {.gdExport.}:bool = true
  var watchIntervalSeconds {.gdExport.}:float = 0.3
  var reloadIntervalSeconds {.gdExport.}:float = 0.3

  var reloadMetaTable:Table[string, ReloadMeta]
  var dependents:Table[string, HashSet[string]]
  var reloadSaveDataTable:Table[string, seq[byte]]
  var reloadingComps:seq[string]
  var watchElapsedSeconds:float
  var reloadElapsedSeconds:float

  var enableNotifications {.gdExport.}:bool = true
  var notification_duration {.gdExport.}:float  = 10.0
  var notification_time_to_fade {.gdExport.}:float = 2.0

  var notifications:seq[ReloadNotification]

  var lineEditPacked:PackedScene
  var vbox:VBoxContainer

  proc getSaveOrder(compName:string):seq[string] =
    if not self.dependents.hasKey(compName):
      result.add compName
      return
    for c in self.dependents[compName]:
      result.add self.getSaveOrder(c)
    result.add compName

  method init() =
    self.lineEditPacked = resource_loader.load("res://_tscn/watcher_lineedit.tscn") as PackedScene

  method enter_tree() =
    self.vbox = self.get_node("VBoxContainer") as VBoxContainer

  method exit_tree() =
    self.lineEditPacked = nil
    self.vbox = nil

  method process(delta: float64) =
    if not self.enableWatch: return

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

    if self.reloadingComps.len > 0:
      if self.reloadElapsedSeconds < self.reloadIntervalSeconds:
        self.reloadElapsedSeconds += delta
        return
      self.reloadElapsedSeconds = 0.0

      var finReloadingComps:seq[string]

      for compName in self.reloadingComps:
        var rmeta = self.reloadMetaTable[compName]
        if not resource_loader.has_cached(rmeta.resourcePath):
          try:
            moveFile(compName.safeDllPath, compName.hotDllPath)
            #reload the scene
            var loaderNode = self.get_node(rmeta.loaderPath)
            if not loaderNode.isNil:
              if rmeta.loaderProc == "add_child":
                var pscene = resource_loader.load(rmeta.resourcePath) as PackedScene
                loaderNode.call_deferred("add_child", toVariant(pscene.instance()))
              else:
                printWarning &"Watcher: calling {rmeta.loaderProc}"
                self.notify(&"Watcher: calling {rmeta.loaderProc}")
                loaderNode.call_deferred(rmeta.loaderProc)
          except:
            printError &"Fail! could not moveFile {compName.safeDllPath} to {compName.hotDllPath}"

          finReloadingComps.add(compName)
        else:
          printError &"Watcher: {compName} still cached"

      self.reloadingComps = self.reloadingComps.filterIt(not (it in finReloadingComps))
      return

    self.watchElapsedSeconds += delta
    if self.watchElapsedSeconds > self.watchIntervalSeconds:
      self.watchElapsedSeconds = 0.0

      for compName in self.reloadMetaTable.keys:
        if (not (compName in self.reloadingComps)) and fileExists(compName.safeDllPath) and
          getLastModificationTime(compName.safeDllPath) > getLastModificationTime(compName.hotDllPath):

          var saveOrder = self.getSaveOrder(compName)
          # save descendents
          for dname in saveOrder:
            var dmeta = self.reloadMetaTable[dname]
            var dnode = self.get_node(dmeta.saverPath)
            var saveData:seq[byte]
            printWarning &"Watcher reloading: calling {dmeta.saverPath} {dmeta.saverProc}"
            self.notify &"Watcher reloading: calling {dmeta.saverPath} {dmeta.saverProc}"

            try:
              discard saveData.fromVariant(dnode.call(dmeta.saverProc))
              self.reloadSaveDataTable[dname] = move(saveData)
            except CallError as e:
              printError &"Watcher reloading: Error '{e.err.error}'. From {compName}.{dmeta.saverProc} @ {dmeta.saverPath}"
              raise
          self.reloadingComps.add(compName)

  proc register_component(compName:string, saverPath:string, loaderPath:string, saverProc="reload", loaderProc="add_child"):seq[byte] {.gdExport.} =
    printWarning &"Watcher registering {compName} @ {saverPath} {loaderPath} {saverProc} {loaderProc}"
    self.notify &"Watcher registering {compName} @ {saverPath} {loaderPath} {saverProc} {loaderProc}"
    if not fileExists(compName.hotDllPath):
      printError &"Watcher failed to register {compName}. No dll with this name."
      return
    try:
      var resourcePath = findCompTscn(compName)
      self.reloadMetaTable[compName] = ReloadMeta(compName:compName, saverPath:saverPath, loaderPath:loaderPath, saverProc:saverProc, loaderProc:loaderProc, resourcePath:resourcePath)

      for parentCompName, parentMeta in self.reloadMetaTable:
        if parentCompName == compName: continue
        if parentMeta.saverPath == loaderPath:
          if not self.dependents.hasKey(parentCompName): self.dependents[parentCompName] = initHashSet[string]()
          self.dependents[parentCompName].incl(compName)

      if self.reloadSaveDataTable.hasKey(compName):
        result = self.reloadSaveDataTable[compName]
        self.reloadSaveDataTable.del(compName)
    except IOError as e:
      printError e.msg

  proc notify(msg:string) =
    var n = ReloadNotification(gdLine: self.lineEditPacked.instance() as LineEdit)
    self.notifications.add n
    n.gdLine.text = msg
    if self.vbox != nil:
      self.vbox.call_deferred("add_child", n.gdLine.toVariant)