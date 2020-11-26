import godot
import godotapi / [node, label]
import hot
import strformat
import tables

gdobj TestComp of Label:
  var tick:int
  var elapsedSeconds:float
  var tickIntervalSeconds:float = 0.1
  var anInt:int = 222
  var aString1:string = "update"

  signal test_sig(a_bool:bool, a_int8:int8, a_string:string)

  method enter_tree() =
    self.text = "TestComp enter_tree"
    register(test_comp)?.load(self.tick, self.aString1)

  method ready() =
    discard self.connect("test_sig", self, "on_test_sig")
    self.emitSignal("test_sig", true.toVariant, 123.toVariant, "hello".toVariant)
    self.emitSignal("test_sig", false.toVariant, (-128).toVariant, "world".toVariant)

  proc on_test_sig(a_bool:bool, a_int8:int8, a_string:string) {.gdExport.} =
    print &"got test_sig {a_bool = } {a_int8 = } {a_string = }"

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