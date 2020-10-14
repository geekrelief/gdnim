import godot
import godotapi / node
import strformat
import storage

import macros

gdobj MsgpackComp of Node:
  var compName = "msgpack_comp"
  var i:int
  var f:float = 2.0
  var s:string = "k!"
  var tickRate:float = 1
  var elapsedSeconds:float

  proc onBeforeReload() =
    save(self.i)

  proc onAfterReload(data:string) =
    load(data, self.i)

  method enter_tree() =
    print "MsgpackComp enter_tree"
    var data = registerReloadMeta(
      self.compName,
      (
        compName: self.compName,
        parentPath: $self.getParent().getPath(),
        reloadProc: proc(){.closure, gcsafe.} =
          self.onBeforeReload()
      )
    )
    self.onAfterReload(data)

  method process(delta:float) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds < self.tickRate: return
    self.elapsedSeconds = 0

    self.i += 1

    print &"MsgPack {self.i = } {self.f = } {self.s = }"