import godot
import godotapi / [node, resource_loader, packed_scene]
import os, strformat, times
from sequtils import filterIt
import tables

const dllDir:string = "_dlls"

func safeDllPath(compName:string):string =
  &"{dllDir}/{compName}_safe.dll"
func hotDllPath(compName:string):string =
  &"{dllDir}/{compname}.dll"
func resourcePath(compName:string):string =
  &"res://{compName}.tscn"

type ReloadMeta = tuple[compName:string, saverPath:string, loaderPath:string, saverProc:string, loaderProc:string]

gdobj Watcher of Node:

  var enableWatch {.gdExport.}:bool = true
  var watchIntervalSeconds {.gdExport.}:float = 0.5
  var reloadIntervalSeconds {.gdExport.}:float = 0.5

  var reloadMetaTable:Table[string, ReloadMeta]
  var reloadSaveDataTable:Table[string, seq[byte]]
  var reloadingKeys:seq[string]
  var watchElapsedSeconds:float
  var reloadElapsedSeconds:float

  method process(delta: float64) =
    if not self.enableWatch: return

    if self.reloadingKeys.len > 0:
      if self.reloadElapsedSeconds < self.reloadIntervalSeconds:
        self.reloadElapsedSeconds += delta
        return
      self.reloadElapsedSeconds = 0.0

      var finReloadingKeys:seq[string]

      for key in self.reloadingKeys:
        var rmeta = self.reloadMetaTable[key]
        var compName = rmeta.compName

        if not resource_loader.has_cached(compName.resourcePath):
          try:
            moveFile(compName.safeDllPath, compName.hotDllPath)
            #reload the scene
            var loaderNode = self.get_node(rmeta.loaderPath)
            if not loaderNode.isNil:
              if rmeta.loaderProc == "add_child":
                var pscene = resource_loader.load(compName.resourcePath) as PackedScene
                loaderNode.call_deferred("add_child", toVariant(pscene.instance()))
              else:
                printWarning &"Watcher: calling {rmeta.loaderProc}"
                loaderNode.call_deferred(rmeta.loaderProc)
          except:
            printWarning &"Fail! could not moveFile {compName.safeDllPath} to {compName.hotDllPath}"

          finReloadingKeys.add(key)
        else:
          printWarning &"Watcher: {compName} still cached"

      self.reloadingKeys = self.reloadingKeys.filterIt(not (it in finReloadingKeys))
      return

    self.watchElapsedSeconds += delta
    if self.watchElapsedSeconds > self.watchIntervalSeconds:
      self.watchElapsedSeconds = 0.0

      for key in self.reloadMetaTable.keys:
        var rmeta = self.reloadMetaTable[key]
        var compName = rmeta.compName
        if (not (key in self.reloadingKeys)) and fileExists(compName.safeDllPath) and
          getLastModificationTime(compName.safeDllPath) > getLastModificationTime(compName.hotDllPath):

          var compNode = self.get_node(rmeta.saverPath)
          var saveData:seq[byte]
          printWarning &"calling {rmeta.saverPath} {rmeta.saverProc}"
          discard saveData.fromVariant(compNode.call(rmeta.saverProc))
          self.reloadSaveDataTable[compName] = saveData
          self.reloadingKeys.add(key)

  proc register_component(compName:string, saverPath:string, loaderPath:string, saverProc="reload", loaderProc="add_child"):seq[byte] {.gdExport.} =
    printWarning &"Watcher registering {compName} @ {saverPath} {loaderPath} {saverProc} {loaderProc}"
    self.reloadMetaTable[compName] = (compName, saverPath, loaderPath, saverProc, loaderProc)
    result = if self.reloadSaveDataTable.hasKey(compName): self.reloadSaveDataTable[compName] else: result