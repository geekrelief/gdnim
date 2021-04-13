import gdnim
import math, times, std/monotimes

gdnim Bullet of Sprite:
  # gun will spawn
  var id: int64
  var velocity = vec2()
  var maxlifeTime: float64 = 20.0
  var startTime: MonoTime
  var startPosition: Vector2
  var radius: float = 43.0

  signal dead(id: int)

  unload:
    self.queue_free()
    save(self.id, self.startTime, self.velocity, self.startPosition)

  reload:
    load(self.id, self.startTime, self.velocity, self.startPosition)

  method ready() =
    self.startTime = getMonoTime()

  proc set_data(id: int64, v: Vector2, p: Vector2) {.gdExport.} =
    self.id = id
    self.velocity = v
    self.global_position = p
    self.startPosition = p + vec2(self.radius, 0.0)

  method process(delta: float64) =
    var elapsedTime: float64 = float64(inNanoseconds(getMonoTime() -
        self.startTime)) / 1_000_000_000.0'f64
    if elapsedTime >= self.maxLifeTime:
      self.queue_free()
      return
    self.position = self.startPosition + self.velocity*elapsedTime + vec2(
        self.radius*cos(elapsedTime*TAU + TAU*0.5), self.radius * sin(
        -elapsedTime*TAU*1.0 - TAU*0.0))
