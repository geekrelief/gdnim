import godot
import godotapi / node
import storage
import strformat
import tables

gdobj TestComp of Node:
  var id:string = "test_comp"
  var a:int
  var elapsedSeconds:float
  var tickIntervalSeconds:float = 2
  var anInt:int = 50

  method init() =
    print "TestComp init"
    var data = registerBeforeReloadProc(self.id,
      proc(){.closure, gcsafe.} =
        self.onBeforeReload()
    )
    self.onAfterReload(data)

  proc onBeforeReload() =
    print "TestComp: onBeforeReload"
    var data = pack(self.a)
    putData(self.id, data)
    self.queue_free()
    print "TestComp: stored data and queue_free"

  proc onAfterReload(data:string) =
    if data.len == 0: return
    print "TestComp: onAfterReload has data!"
    var a:int
    unpack(data, a)
    self.a = a

  method process(delta:float) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds >= self.tickIntervalSeconds:
      self.elapsedSeconds = 0
      self.a += 1
      self.printData

  proc printData() =
    print &"TestComp {self.tickIntervalSeconds}: {self.a}, {self.anInt}"