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
  var anInt:int = 6
  var aString1:string = "hi"

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

  proc onAfterReload(data:string) =
    load(data, self.tick, self.aString1)

  method process(delta:float) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds >= self.tickIntervalSeconds:
      self.elapsedSeconds = 0
      self.tick += 1
      self.printData

  proc printData() =
    print &"TestComp {self.tickIntervalSeconds}: {self.tick}, {self.anInt}, {self.aString1}"