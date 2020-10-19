import godot
import godotapi / node
import strformat

import msgpack4nim

gdobj Machine of Node:

  var intVal = 4
  var int2Val = 22
  var strVal = "so far so good"
  var tickRate = 2.0
  var elapsedSeconds:float

  method enter_tree() =
    var cwatcher = self.get_node("/root/CallsWatcher") #case sensitive
    if not cwatcher.isNil:
      print "Machine: Found CallsWatcher, calling register_component"

      var data = cwatcher.call("register_component",
        "machine".toVariant,
        ($self.get_parent().get_path()).toVariant,
        ($self.get_path()).toVariant).asString
      if data.len > 0:
        var b = MsgStream.init(data)
        var i:int
        b.unpack(i)
        self.intVal = i

  proc reload():string {.gdExport.} =
    print "Machine prep reload"
    self.queue_free()
    var b = MsgStream.init()
    b.pack(self.intVal)
    b.data

  method process(delta:float64) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds < self.tickRate: return
    self.elapsedSeconds = 0.0

    print &"Machine tick: {self.intVal = } {self.int2Val} {self.strVal} len {len(self.strVal)}"