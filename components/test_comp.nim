import godot
import godotapi / node
import hot
import strformat
import tables

gdobj TestComp of Node:
  var tick:int
  var elapsedSeconds:float
  var tickIntervalSeconds:float = 2
  var anInt:int = 111
  var aString1:string = "longer"

  method enter_tree() =
    print "TestComp enter_tree"
    var b = register(test_comp)
    load(b, self.tick, self.aString1)

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()
    save(self.tick, self.aString1)

  method process(delta:float) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds >= self.tickIntervalSeconds:
      self.elapsedSeconds = 0
      self.tick += 1
      self.printData

  proc printData() =
    print &"TestComp {self.tickIntervalSeconds}: {self.tick}, {self.anInt}, {self.aString1}"