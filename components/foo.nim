import godot
import godotapi / [node_2d]
import hot

gdobj Foo of Node2D:

  method ready*() =
    print("Hello from Nim hot reload")

  method enter_tree() =
    discard register(foo)

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()
