import godot
import godotapi / [global_constants, engine, node, objects]
import godotapi / [resource_loader, texture, sprite, packed_scene, scene_tree, viewport, label]
import godotapi / scene_tree_timer
import os, strutils, strformat, times, sequtils
import tables

const dllDir:string = "_dlls"

func safeDllPath(compName:string):string =
  &"{dllDir}/{compName}_safe.dll"
func hotDllPath(compName:string):string =
  &"{dllDir}/{compname}.dll"
func resourcePath(compName:string):string =
  &"res://{compName}.tscn"

type ReloadMeta = tuple[compName:string, parentPath:string, scenePath:string]

gdobj Watcher of Node:

  var enableWatch {.gdExport.}:bool = true
  var watchIntervalSeconds {.gdExport.}:float = 0.5
  var reloadIntervalSeconds {.gdExport.}:float = 0.5

  var reloadMetaTable:Table[string, ReloadMeta]
  var reloadSaveDataTable:Table[string, string]
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
            var parentNode = self.get_node(rmeta.parentPath)
            if not parentNode.isNil:
              var pscene = resource_loader.load(compName.resourcePath) as PackedScene
              parentNode.call_deferred("add_child", toVariant(pscene.instance()))
          except:
            print &"Fail! could not moveFile {compName.safeDllPath} to {compName.hotDllPath}"

          finReloadingKeys.add(key)
        else:
          print &"Watcher: {compName} still cached"

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

          var compNode = self.get_node(rmeta.scenePath)
          var saveData = compNode.call("reload").asString
          self.reloadSaveDataTable[compName] = saveData
          self.reloadingKeys.add(key)

  proc register_component(compName:string, parentPath:string, scenePath:string):string {.gdExport.} =
    print &"Watcher registering {compName} @ {scenePath}"
    self.reloadMetaTable[compName] = (compName:compName, parentPath:parentPath, scenePath:scenePath)
    result = if self.reloadSaveDataTable.hasKey(compName): self.reloadSaveDataTable[compName] else: ""