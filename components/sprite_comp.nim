import godot
import godotapi / [sprite]
import math
import times
import storage
import macros

#[
dumpAstGen:
  if data.len == 0: return
  var s = MsgStream.init(data)
  var radius:int
  var speed:float
  s.unpack(radius)
  self.radius = radius
  s.unpack(speed)
  self.speed = speed
]#

gdobj SpriteComp of Sprite:
  var compName = "sprite_comp"
  var startPos* {.gdExport.}:Vector2
  var radius* {.gdExport.}:int = 50
  var speed* {.gdExport.}:float = 0.55
  var startTime:DateTime
  var first = false

  method enter_tree() =
    var data = registerReloadMeta(self.compName, (
      compName: self.compName,
      parentPath: $self.getParent().getPath(),
      reloadProc: proc(){.closure, gcsafe.} =
        self.onBeforeReload()
      ))
    self.onAfterReload(data)

  method ready() =
    print "Plugin ready"
    self.startPos = self.position + vec2(200.0, 100.0)
    self.startTime = now()

  proc onBeforeReload() =
    print "SpriteComp: onBeforeReload"
    save(self.radius)
    #[
    var s = MsgStream.init()
    s.pack(self.radius)
    #s.pack(self.speed)
    putData(self.compName, s.data)
    self.queue_free()
    ]#

  proc onAfterReload(data:string) =
    load(self.radius)
    #[
    if data.len == 0: return
    var s = MsgStream.init(data)
    var radius:int
    s.unpack(radius)
    self.radius = radius
    ]#
    #[
    var speed:float
    s.unpack(speed)
    self.speed = speed
    ]#

  method process(delta: float64) =
    var deltaSeconds:float64 =  float64((now() - self.startTime).inMilliseconds()) / 1000.0
    var delta_angle = deltaSeconds * self.speed * TAU
    if self.first:
      self.position = vec2(self.startPos.x + 2 * self.radius.toFloat * cos(delta_angle) + self.radius.toFloat * cos(2.25*delta_angle),
        self.startPos.y + self.radius.toFloat * sin(2*delta_angle) + self.radius.toFloat * sin(0.01*self.position.x))
    else:
      self.position = vec2(self.startPos.x + 2 * self.radius.toFloat * cos(delta_angle),
        self.startPos.y + self.radius.toFloat * sin(2*delta_angle))