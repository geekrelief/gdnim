import godot
import godotapi / node
import strformat
import hot

gdobj MsgpackComp of Node:
  var compName = "msgpack_comp"
  var i:int
  var f:float = 2.0
  var s:string = "ok! oh yeah"
  var tickRate:float = 1
  var elapsedSeconds:float

  method enter_tree() =
    print "MsgpackComp enter_tree"
    load(self.i)

  proc reload():seq[byte] {.gdExport.} =
    save(self.i)

  method process(delta:float) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds < self.tickRate: return
    self.elapsedSeconds = 0

    self.i += 1

    print &"MsgPack {self.i = } {self.f = } {self.s = }"