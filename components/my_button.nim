import gdnim, godotapi / [button]

gdobj MyButton of Button:
  var count:int = 0

  proc hot_unload():seq[byte] {.gdExport.} =
    self.queue_free()
    save(self.rectPosition, self.count)

  method enter_tree() =
    register(my_button)?.load(self.rectPosition, self.count)
    discard self.connect("pressed", self, "clicked")

  proc clicked() {.gdExport.} =
    inc self.count
    var msg =  case self.count:
      of 1: "once"
      of 2: "twice"
      of 3: "thrice"
      else: $self.count & " times"
    print "You clicked MyButton " & msg & "!"