import godot
import godotapi / [sprite, global_constants]
import strformat
import math
import msgpack4nim

gdobj Bullet of Sprite:
  # gun will spawn
  var id:string
  var velocity = vec2()
  var maxlifeTime:float = 40.0
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
      self.isDead = true
      self.emitSignal("dead", self.id.toVariant)
      return
    self.position = self.position + self.velocity + vec2(0, 2 * sin(self.elapsedLife*TAU*1.0 - TAU*0.25))

  proc packData():seq[byte] {.gdExport.} =
    var b = MsgStream.init()
    b.pack(self.id)
    b.pack(self.elapsedLife)
    b.pack(self.velocity)
    b.pack(self.position)
    cast[seq[byte]](b.data)

  proc unpackData(data:seq[byte]):string {.gdExport.} =
    var b = MsgStream.init(cast[string](data))
    var id:string
    b.unpack(id)
    self.id = id
    var elapsedLife:float
    b.unpack(elapsedLife)
    self.elapsedLife = elapsedLife
    var velocity:Vector2
    b.unpack(velocity)
    self.velocity = velocity
    var position:Vector2
    b.unpack(position)
    self.position = position
    self.id