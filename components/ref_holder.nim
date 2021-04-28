import gdnim, godotapi / [node]
import strformat

const SpriteCompPath = "/root/Node2D/SpriteComp"
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
      discard watcher.connect("instance_unloaded", self, "sprite_unloaded")
      discard watcher.connect("instance_loaded", self, "sprite_loaded")
    self.spriteCompNode = self.getNode(SpriteCompPath)

  proc sprite_unloaded(nodePath: string) {.gdExport.} =
    if nodePath == SpriteCompPath:
      printWarning &"RefHolder: {nodePath} unloaded, freeing ref"
      self.spriteCompNode = nil

  proc sprite_loaded(nodePath: string) {.gdExport.} =
    if nodePath == SpriteCompPath:
      printWarning &"RefHolder: {nodePath} loaded, storing ref"
      self.spriteCompNode = self.getNode(SpriteCompPath)
