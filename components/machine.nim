import godot
import godotapi / node
import strformat

import msgpack4nim
import hot

gdobj Machine of Node:

  var compName = "machine"
  var intVal = 4
  var int2Val = 11
  var floatVal = 0.8
  var strVal = "inside"
  var tickRate = 2.0
  var elapsedSeconds:float

  method enter_tree() =
    print "Machine enter_tree"
    load(register(machine), self.floatVal)

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()
    save(self.floatVal)

  method process(delta:float64) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds < self.tickRate: return
    self.elapsedSeconds = 0.0

    print &"Machine tick: {self.intVal = } {self.floatVal = } {self.int2Val} {self.strVal} len {len(self.strVal)}"