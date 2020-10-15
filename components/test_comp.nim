import godot
import godotapi / node
import storage
import strformat
import tables

gdobj TestComp of Node:
  var compName:string = "test_comp"
  var tick:int
  var elapsedSeconds:float
  var tickIntervalSeconds:float = 2
  var anInt:int = 3
  var aString1:string = "hi th"

  method enter_tree() =
    print "TestComp enter_tree"
    var data = registerReloadMeta(self.compName, (
      compName: self.compName,
      parentPath: $self.getParent().getPath(),
      reloadProc: proc(){.closure, gcsafe.} =
        self.onBeforeReload()
      ))
    self.onAfterReload(data)

  proc onBeforeReload() =
    save(self.tick, self.aString1)
    #[
    var b = MsgStream.init()
    b.pack(self.tick)
    b.pack(self.aString1)
    putData(self.compName, b.data)
    self.queue_free()
    ]#

  proc onAfterReload(data:string) =
    load(self.tick, self.aString1)
    #[
    if data.len == 0: return
    print "TestComp: onAfterReload has data!"
    var b = MsgStream.init(data)
    var tick:int
    b.unpack(tick)
    self.tick = tick
    var aString1:string
    b.unpack(aString1)
    self.aString1 = aString1
    ]#

  method process(delta:float) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds >= self.tickIntervalSeconds:
      self.elapsedSeconds = 0
      self.tick += 1
      self.printData

  proc printData() =
    print &"TestComp {self.tickIntervalSeconds}: {self.tick}, {self.anInt}, {self.aString1}"