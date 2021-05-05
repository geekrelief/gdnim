import gdnim, godotapi / [node]
import strformat

const SpriteCompPath = "/root/Node2D/SpriteComp"
# shows how we can get a signal when the
gdnim RefHolder of Node:

  var spriteCompNode: Node

  unload:
    save()

  reload:
    load()

  method enter_tree() =
    when defined(does_reload):
      var watcher = self.get_node("/root/Watcher")
      if watcher.isNil: return
      #discard watcher.connect(WatcherReloadingStart, self, "on_reload_start")
      #discard watcher.connect(WatcherReloadingComplete, self, "on_reload_complete")
      discard watcher.connect(WatcherInstanceUnloaded, self, "sprite_unloaded")
      discard watcher.connect(WatcherInstanceLoaded, self, "sprite_loaded")
    self.spriteCompNode = self.getNode(SpriteCompPath)

  proc on_reload_start(compName:string) {.gdExport.} =
    printWarning &"RefHolder: reload started on {compName}"

  proc on_reload_complete(compName:string) {.gdExport.} =
    printWarning &"RefHolder: reload completed on {compName}"

  proc sprite_unloaded(nodePath: string) {.gdExport.} =
    if nodePath == SpriteCompPath:
      printWarning &"RefHolder: {nodePath} unloaded, freeing ref"
      self.spriteCompNode = nil

  proc sprite_loaded(nodePath: string) {.gdExport.} =
    if nodePath == SpriteCompPath:
      printWarning &"RefHolder: {nodePath} loaded, storing ref"
      self.spriteCompNode = self.getNode(SpriteCompPath)
