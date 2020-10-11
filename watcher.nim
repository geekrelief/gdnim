import godot
import godotapi / [global_constants, engine, node, objects]
import godotapi / [resource_loader, texture, sprite, packed_scene, scene_tree, viewport, label]
import os, strutils, strformat, times, sequtils
import storage

const dllDir:string = "_dlls"

func safeDllPath(compName:string):string =
  &"{dllDir}/{compName}_safe.dll"
func hotDllPath(compName:string):string =
  &"{dllDir}/{compname}.dll"
func resourcePath(compName:string):string =
  &"res://{compName}.tscn"

gdobj Watcher of Node:

  var enableWatch {.gdExport.}:bool = true
  var watchIntervalSeconds {.gdExport.}:float = 0.3
  var reloadIntervalSeconds {.gdExport.}:float = 0.3

  var reloadingComps:seq[string]
  var watchElapsedSeconds:float
  var reloadElapsedSeconds:float

#[
  method init() =
    var arg0 = newDictionary()
    arg0["name".toVariant] = "comp_name".toVariant
    arg0["type".toVariant] = TYPE_STRING.toVariant
    var args = newArray(arg0.toVariant)
    print "Watcher: addUserSignal"
    self.addUserSignal("reload", args)
]#

#[
  method ready() =
    print "Watcher: trying to getBeforeReloadProcs"
    let beforeReloadProcs = getBeforeReloadProcs()
    var count = beforeReloadProcs.len
    print &"Watcher: got beforeReloadProcs {count}"
    var err = self.connect("reload", self, "on_reload")
    print &"Watcher connect error: {err}"
    print "Watcher emit reload"
    self.emitSignal("reload", "test_comp".toVariant)

  proc onReload*(vcompName:Variant) {.gdExport.} =
    var compName:string
    discard compName.fromVariant(vcompName)
    print &"Watcher onReload {compName}"
]#

  method process(delta: float64) =
    if not self.enableWatch: return

    if self.reloadingComps.len > 0:
      if self.reloadElapsedSeconds < self.reloadIntervalSeconds:
        self.reloadElapsedSeconds += delta
        return
      self.reloadElapsedSeconds = 0.0

      var finReloadingComps:seq[string]

      for compName in self.reloadingComps:
        print &"Watcher: check cache for {compName}"
        if not resource_loader.has_cached(compName.resourcePath):
          try:
            print &"Watcher {compName} dll move safe to hot"
            moveFile(compName.safeDllPath, compName.hotDllPath)
            print &"Watcher Success! moveFile {compName.safeDllPath} to {compName.hotDllPath} worked!"
            #reload the scene
            var pscene = resource_loader.load(compName.resourcePath) as PackedScene
            #TODO: lookup where to insert instead of under the Watcher
            self.call_deferred("add_child", toVariant(pscene.instance()))
          except:
            print &"Fail! could not moveFile {compName.safeDllPath} to {compName.hotDllPath}"

          finReloadingComps.add(compName)
        else:
          print &"Watcher: {compName} still cached"

      self.reloadingComps = self.reloadingComps.filterIt(not (it in finReloadingComps))
      return

    self.watchElapsedSeconds += delta
    if self.watchElapsedSeconds > self.watchIntervalSeconds:
      self.watchElapsedSeconds = 0.0

      let beforeReloadProcs = getBeforeReloadProcs()
      for compName in beforeReloadProcs.keys:
        #print &"Watcher checking {compName}"
        if (not (compName in self.reloadingComps)) and fileExists(compName.safeDllPath) and getLastModificationTime(compName.safeDllPath) > getLastModificationTime(compName.hotDllPath):
          print &"Watcher: prep reload {compName}"
          beforeReloadProcs[compName]()
          self.reloadingComps.add(compName)

  method notification(what:int64) =
    if what == NOTIFICATION_PREDELETE:
      print "Watcher: predelete"