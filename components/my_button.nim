import gdnim

gdnim MyButton of Button:
  var count {.gdExport.}: int = 0
  var clickPrefix: string = "My Button clicked "

  unload:
    save()

  reload:
    load()
    discard self.connect("pressed", self, "clicked")

  proc clicked() {.gdExport.} =
    inc self.count
    var msg = case self.count:
      of 1: "once"
      of 2: "twice"
      of 3: "thrice"
      else: $self.count & " times"
    print self.clickPrefix & msg & "!"
