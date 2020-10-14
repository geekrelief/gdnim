import godot
import godotapi / node
import strformat
import storage

import macros

#[
dumpAstGen:
  if data.len == 0: return
  var b = MsgStream.init(data)
  var i:int
  b.unpack(i)
  self.i = i
]#

  #[
  for arg in args:
    echo arg.astGenRepr
    echo arg[1].astGenRepr
    var t = getType(arg[1])
    echo t


macro load*(args: varargs[typed]):untyped =
  echo args.astGenRepr
  discard
  ]#

gdobj MsgpackComp of Node:
  var compName = "msgpack_comp"
  var i:int
  var f:float = 18.0
  var s:string = "dot"
  var tickRate:float = 1
  var elapsedSeconds:float

  proc onBeforeReload() =
    save(self.i, self.f)

  #[
  proc test_load() =
    load:
      self.i
      self.f
      self.s
  ]#
  #[
  proc onBeforeReload() =
  ]#

  proc onAfterReload(data:string) =
    if data.len == 0: return
    var b = MsgStream.init(data)
    var i:int
    b.unpack(i)
    self.i = i
    var f:float
    b.unpack(f)
    self.f = f
    #[
    var s:string
    b.unpack(s)
    self.s = s
    ]#

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

    var i = self.i
    var f = self.f
    var s = self.s

    print &"MsgPack {i=} {f=} {s=}"
