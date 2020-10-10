import godot
import godotapi / node
import storage_api
import strformat
import tables

gdobj TestComp of Node:
  var id:string = "test_comp"
  var a:int
  var elapsedSeconds:float
  var tickIntervalSeconds:float = 2
  var anInt:int = 355

  method init() =
    print "TestComp init"
    var data = registerBeforeReloadProc(self.id,
      proc(){.closure, gcsafe.} =
        self.onBeforeReload()
    )
    self.onAfterReload(data)

  method ready() =
    print "TestComp enter_tree trying to connect"
    var watcher = self.get_parent()
    print watcher.name
    var err = watcher.connect("reload", self, "on_reload")
    print &"TestComp reload connect error: {err}"

  proc onReload*(vcompName:Variant) {.gdExport.} =
    var compName:string
    discard compName.fromVariant(vcompName)
    print &"TestComp: onReload {compName}"
    print &"TestComp: self.a = {self.a}"
    var data = pack(self.a)
    var sdata = stringify(data)
    print &"TestComp: packed {sdata}"

  proc onBeforeReload() =
    print "TestComp: onBeforeReload"
    #[
    echo self.a
    var data = pack(self.a)
    putData(self.id, data)
    self.queue_free()
    ]#

  proc onAfterReload(data:string) =
    if data.len == 0: return
    print "TestComp: onAfterReload has data!"
    var a:int
    unpack(data, a)
    self.a = a

  method process(delta:float) =
    self.elapsedSeconds += delta
    if self.elapsedSeconds >= self.tickIntervalSeconds:
      self.elapsedSeconds = 0
      self.a += 1
      self.printData

  proc printData() =
    print &"TestComp {self.tickIntervalSeconds}: {self.a}, {self.anInt}"