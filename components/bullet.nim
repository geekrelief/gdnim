import godot
import godotapi / [sprite, global_constants]
import strformat
import math
import hot

gdobj Bullet of Sprite:
  # gun will spawn
  var id:int64
  var velocity = vec2()
  var maxlifeTime:float = 30.0
  var elapsedLife:float
  var isDead:bool

  signal dead(id:int)

  method init() =
    self.isDead = false

  proc setData(id:int64, v:Vector2, p:Vector2) {.gdExport.} =
    self.id = id
    self.velocity = v
    self.global_position = p

  method process(delta:float64) =
    if self.isDead: return

    self.elapsedLife += delta
    if self.elapsedLife >= self.maxLifeTime:
      self.isDead = true
      self.emitSignal("dead", self.id.toVariant)
      return
    self.position = self.position + self.velocity + vec2(0, 3 * sin(self.elapsedLife*TAU*1.0 - TAU*0.25))

  proc packData():seq[byte] {.gdExport.} =
    save(self.id, self.elapsedLife, self.velocity, self.position)

  proc unpackData(data:seq[byte]):int64 {.gdExport.} =
    load(data, self.id, self.elapsedLife, self.velocity, self.position)
    self.id