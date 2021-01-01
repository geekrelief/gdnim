import godot
import godotapi / [sprite, global_constants]
import strformat
import math
import hot
import times
import std/monotimes

gdobj Bullet of Sprite:
  # gun will spawn
  var id:int64
  var velocity = vec2()
  var maxlifeTime:float64 = 10.0
  var startTime:MonoTime
  var isDead:bool
  var startPosition:Vector2
  var radius:float = 30.0

  signal dead(id:int)

  method init() =
    self.isDead = false
    self.startTime = getMonoTime()


  proc setData(id:int64, v:Vector2, p:Vector2) {.gdExport.} =
    self.id = id
    self.velocity = v
    self.global_position = p
    self.startPosition = p + vec2(self.radius, 0.0)

  method process(delta:float64) =
    if self.isDead: return
    var elapsedTime:float64 = float64(inNanoseconds(getMonoTime() - self.startTime)) / 1_000_000_000.0'f64
    if elapsedTime >= self.maxLifeTime:
      self.isDead = true
      self.emitSignal("dead", self.id.toVariant)
      return
    self.position = self.startPosition + self.velocity*elapsedTime + vec2(self.radius*cos(elapsedTime*TAU + TAU*0.5), self.radius * sin(-elapsedTime*TAU*1.0 - TAU*0.0))

  proc packData():seq[byte] {.gdExport.} =
    save(self.id, self.startTime, self.velocity, self.position)

  proc unpackData(data:seq[byte]):int64 {.gdExport.} =
    load(data, self.id, self.startTime, self.velocity, self.position)
    self.id