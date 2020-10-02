import godot
import godotapi / [sprite]
import math
import times

gdobj Plugin of Sprite:
  var startPos* {.gdExport.}:Vector2
  var radius* {.gdExport.}:int = 60
  var speed* {.gdExport.}:float = 0.5
  var startTime:DateTime

  method ready*() =
    print "Plugin ready"
    self.startPos = self.position
    self.startTime = now()

  method process*(delta: float64) =
    var deltaSeconds:float64 =  float64((now() - self.startTime).inMilliseconds()) / 1000.0
    var delta_angle = deltaSeconds * self.speed * TAU
    self.position = vec2(self.startPos.x + self.radius.toFloat * cos(delta_angle), self.startPos.y + self.radius.toFloat * sin(delta_angle))