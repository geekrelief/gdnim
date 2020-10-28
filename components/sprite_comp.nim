import godot
import godotapi / [sprite]
import math
import times
import hot

gdobj SpriteComp of Sprite:
  var compName = "sprite_comp"
  var startPos* {.gdExport.}:Vector2
  var radius* {.gdExport.}:int = 100
  var speed* {.gdExport.}:float = 0.55
  var startTime:DateTime
  var first = true

  method enter_tree() =
    print "SpriteComp enter_tree"
    var b = register(sprite_comp)
    load(b, self.speed)

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()
    save(self.speed)

  method ready() =
    print "Plugin ready"
    self.startPos = self.position + vec2(200.0, 100.0)
    self.startTime = now()


  method process(delta: float64) =
    var deltaSeconds:float64 =  float64((now() - self.startTime).inMilliseconds()) / 1000.0
    var delta_angle = deltaSeconds * self.speed * TAU
    if self.first:
      self.position = vec2(self.startPos.x + 2 * self.radius.toFloat * cos(delta_angle) + self.radius.toFloat * cos(2.25*delta_angle),
        self.startPos.y + self.radius.toFloat * sin(2*delta_angle) + self.radius.toFloat * sin(0.01*self.position.x))
    else:
      self.position = vec2(self.startPos.x + 2 * self.radius.toFloat * cos(delta_angle),
        self.startPos.y + self.radius.toFloat * sin(2*delta_angle))