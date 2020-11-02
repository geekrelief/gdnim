import godot
import godotapi / [node, label]
import hot
import strformat
import tables

gdobj TestComp of Label:
  var tick:int
  var elapsedSeconds:float
  var tickIntervalSeconds:float = 0.1
  var anInt:int = 111
  var aString1:string = "update"

  method enter_tree() =
    self.text = "TestComp enter_tree"
    register(test_comp)?.load(self.tick, self.aString1)

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()
    save(self.tick, self.aString1)

  method process(delta:float) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds >= self.tickIntervalSeconds:
      self.elapsedSeconds = 0
      self.tick += 1
      self.printData()

  proc printData() =
    self.text = &"TestComp test {self.tickIntervalSeconds}: {self.tick}, {self.anInt}, {self.aString1}"