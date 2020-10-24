import godot
import godotapi / [sprite, global_constants]
import strformat
import math


gdobj Bullet of Sprite:
  # gun will spawn
  var id:string
  var velocity = vec2()
  var maxlifeTime:float = 10.0
  var elapsedLife:float
  var isDead:bool

  method init() =
    self.isDead = false
    var arg0 = newDictionary()
    arg0["name".toVariant] = "id".toVariant
    arg0["type".toVariant] = TYPE_STRING.toVariant
    var args = newArray(arg0.toVariant)
    self.addUserSignal("dead", args)

  proc setData(id:string, v:Vector2, p:Vector2) {.gdExport.} =
    print &"set bullet data {id} {v} {p}"
    self.id = id
    self.velocity = v
    self.global_position = p

  method process(delta:float64) =
    if self.isDead: return

    self.elapsedLife += delta
    if self.elapsedLife >= self.maxLifeTime:
      print &"{self.id} is dead"
      self.isDead = true
      self.emitSignal("dead", self.id.toVariant)
      return
    self.position = self.position + self.velocity + vec2(0, 1 * sin(self.elapsedLife*TAU*0.55-TAU*0.25))

  proc getData():seq[float] {.gdExport.} =
    result.setLen(4)
    result[0] = self.velocity.x
    result[1] = self.velocity.y
    result[2] = self.position.x
    result[3] = self.position.y