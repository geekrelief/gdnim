import godot
import godotapi / node
import strformat
import hot

gdobj MsgpackComp of Node:
  var i:int
  var f:float = 2.0
  var s:string = "cynix"
  var tickRate:float = 1
  var elapsedSeconds:float

  method enter_tree() =
    print "MsgpackComp enter_tree"
    var b = register(msgpack_comp)
    load(b, self.i)

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()
    save(self.i)

  method process(delta:float) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds < self.tickRate: return
    self.elapsedSeconds = 0

    self.i += 1

    print &"MsgPack {self.i = } {self.f = } {self.s = }"