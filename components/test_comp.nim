import gdnim
import strformat, tables

gdnim TestComp of Label:
  var tick: int
  var elapsedSeconds: float
  var tickIntervalSeconds: float = 0.1
  var anInt: int = 123
  var aString1: string = "update"

  signal test_sig(a_bool: bool, a_int8: int8, a_string: string)

  unload:
    self.queue_free()
    save(self.tick, self.aString1)

  reload:
    load(self.tick, self.aString1)

  method ready() =
    self.text = "TestComp enter_tree"

  method ready() =
    discard self.connect("test_sig", self, "on_test_sig")
    toV self.emit_signal("test_sig", [true, 123, "hello"])
    toV self.emit_signal("test_sig", [false, (-128), "world"])

  proc on_test_sig(a_bool: bool, a_int8: int8, a_string: string) {.gdExport.} =
    print &"got test_sig {a_bool = } {a_int8 = } {a_string = }"

  method process(delta: float) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds >= self.tickIntervalSeconds:
      self.elapsedSeconds = 0
      self.tick += 1
      self.printData()

  proc printData() =
    self.text = &"TestComp {self.tickIntervalSeconds}: {self.tick}, {self.anInt}, {self.aString1}"
