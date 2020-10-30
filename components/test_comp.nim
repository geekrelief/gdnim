import godot
import godotapi / [node, label]
import hot
import strformat
import tables

gdobj TestComp of Label:
  var tick:int
  var elapsedSeconds:float
  var tickIntervalSeconds:float = 1.4
  var anInt:int = 111
  var aString1:string = "longer"

  method enter_tree() =
    print "TestComp enter_tree"
    print &"text {self.text}"
    self.text = "TestComp" & " 2"
    register(test_comp)?.load(self.tick, self.aString1)

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
    print &"TestComp ok {self.tickIntervalSeconds}: {self.tick}, {self.anInt}, {self.aString1}"
    #self.text = &"TestComp {self.tickIntervalSeconds}: {self.tick}, {self.anInt}, {self.aString1}"