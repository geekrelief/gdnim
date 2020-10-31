import godot
import godotapi / [node, resource_loader, packed_scene]
import os, strformat, times
from sequtils import filterIt
import tables
import sets

const dllDir:string = "_dlls"

func safeDllPath(compName:string):string =
  &"{dllDir}/{compName}_safe.dll"
func hotDllPath(compName:string):string =
  &"{dllDir}/{compname}.dll"
func resourcePath(compName:string):string =
  &"res://{compName}.tscn"

type ReloadMeta = object
  compName:string
  saverPath:string
  loaderPath:string
  saverProc:string
  loaderProc:string

gdobj Watcher of Node:

  var enableWatch {.gdExport.}:bool = true
  var watchIntervalSeconds {.gdExport.}:float = 0.5
  var reloadIntervalSeconds {.gdExport.}:float = 0.5

  var reloadMetaTable:Table[string, ReloadMeta]
  var dependents:Table[string, HashSet[string]]
  var reloadSaveDataTable:Table[string, seq[byte]]
  var reloadingKeys:seq[string]
  var watchElapsedSeconds:float
  var reloadElapsedSeconds:float

  proc getSaveOrder(compName:string):seq[string] =
    if not self.dependents.hasKey(compName):
      result.add compName
      return
    for c in self.dependents[compName]:
      result.add self.getSaveOrder(c)
    result.add compName

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
            printError &"Fail! could not moveFile {compName.safeDllPath} to {compName.hotDllPath}"

          finReloadingKeys.add(key)
        else:
          printError &"Watcher: {compName} still cached"

      self.reloadingKeys = self.reloadingKeys.filterIt(not (it in finReloadingKeys))
      return

    self.watchElapsedSeconds += delta
    if self.watchElapsedSeconds > self.watchIntervalSeconds:
      self.watchElapsedSeconds = 0.0

      for compName in self.reloadMetaTable.keys:
        var rmeta = self.reloadMetaTable[compName]
        if (not (compName in self.reloadingKeys)) and fileExists(compName.safeDllPath) and
          getLastModificationTime(compName.safeDllPath) > getLastModificationTime(compName.hotDllPath):

          var saveOrder = self.getSaveOrder(compName)
          self.reloadingKeys.add(compName)
          # save descendents
          for dname in saveOrder:
            var dmeta = self.reloadMetaTable[dname]
            var dnode = self.get_node(dmeta.saverPath)
            var saveData:seq[byte]
            printWarning &"calling {dmeta.saverPath} {dmeta.saverProc}"
            discard saveData.fromVariant(dnode.call(dmeta.saverProc))
            self.reloadSaveDataTable[dname] = saveData

  proc register_component(compName:string, saverPath:string, loaderPath:string, saverProc="reload", loaderProc="add_child"):seq[byte] {.gdExport.} =
    printWarning &"Watcher registering {compName} @ {saverPath} {loaderPath} {saverProc} {loaderProc}"
    self.reloadMetaTable[compName] = ReloadMeta(compName:compName, saverPath:saverPath, loaderPath:loaderPath, saverProc:saverProc, loaderProc:loaderProc)

    for parentCompName, parentMeta in self.reloadMetaTable:
      if parentCompName == compName: continue
      if parentMeta.saverPath == loaderPath:
        if not self.dependents.hasKey(parentCompName): self.dependents[parentCompName] = initHashSet[string]()
        self.dependents[parentCompName].incl(compName)

    if self.reloadSaveDataTable.hasKey(compName):
      result = self.reloadSaveDataTable[compName]
      self.reloadSaveDataTable.del(compName)