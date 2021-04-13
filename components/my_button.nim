import gdnim

gdnim MyButton of Button:
  var count: int = 0

  unload:
    save(self.rectPosition, self.count)

  reload:
    load(self.rectPosition, self.count)

  method ready() =
    discard self.connect("pressed", self, "clicked")

  proc clicked() {.gdExport.} =
    inc self.count
    var msg = case self.count:
      of 1: "once"
      of 2: "twice"
      of 3: "thrice"
      else: $self.count & " times"
    print "You clicked MyButton " & msg & "!"
