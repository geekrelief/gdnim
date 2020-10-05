import godot
import godotapi / [sprite]
import math
import times
import watcher

gdobj Plugin of Sprite:
  var startPos* {.gdExport.}:Vector2
  var radius* {.gdExport.}:int = 30
  var speed* {.gdExport.}:float = 0.5
  var startTime:DateTime

  method ready*() =
    print "Plugin ready"
    self.startPos = self.position
    self.startTime = now()

    var watcher = self.get_parent() as Watcher
    self.onPostReload(watcher.takePostReload())

    watcher.setPreReloadCB(proc():string {.gcsafe, locks: 0.} =
      self.onPreReload()
    )


  method process*(delta: float64) =
    var deltaSeconds:float64 =  float64((now() - self.startTime).inMilliseconds()) / 1000.0
    var delta_angle = deltaSeconds * self.speed * TAU
    self.position = vec2(self.startPos.x + self.radius.toFloat * cos(delta_angle), self.startPos.y + self.radius.toFloat * sin(delta_angle))

  proc onPreReload*():string =
    try:
      print "Plugin.onPreReload saving data to MsgStream"
      result = pack(self.radius)
      print(stringify(result))
    except:
      print "Plugin.onPreReload error"

  proc onPostReload*(data:string) =
    if data.len == 0:
      print "Plugin.onPostReload data is empty"
      return
    try:
      print "Plugin.onPostReload restoring data from MsgStream"
      print(stringify(data))
      var radius:int
      unpack(data, radius)
      self.radius = radius
      print self.radius
    except:
      print "Plugin.onPostReload error"