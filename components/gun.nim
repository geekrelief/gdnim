import gdnim
import tables, strformat, sequtils

gdnim Gun of Sprite:
  var bulletRes:PackedScene
  var bulletSpawnPoint:Node2D

  var nextBulletId:int64
  var fireTime:float64
  var fireInterval:float64 = 0.3

  unload:
    self.queue_free()
    save(self.nextBulletId, self.position)

  reload:
    load(self.nextBulletId, self.position)

  dependencies:
    bullet:
      self.bulletRes = loadScene("bullet")

  method enter_tree() =
    self.bulletSpawnPoint = self.get_node("BulletSpawnPoint") as Node2D

    var button_fireSingle = self.get_parent().get_node("Button_FireSingle")
    discard button_fireSingle.connect("pressed", self, "fire_single")

  proc createBullet(v:Vector2, p:Vector2) =
    if self.bulletRes == nil: return
    var id = self.nextBulletId
    inc self.nextBulletId
    var b = self.bulletRes.instance()
    discard toV b.call("set_data", [id, v, p])
    self.get_tree().root.add_child(b)

  proc fire_single() {.gdExport.} =
    for i in 0..10:
      self.createBullet(vec2(120.0 + i.toFloat * 6.0,0.0), self.bulletSpawnPoint.global_position)

    self.createBullet(vec2(120.0, 0.0), self.bulletSpawnPoint.global_position)
    self.createBullet(vec2(100.0, 0.0), self.bulletSpawnPoint.global_position)

  method process(delta:float64) =
    self.fireTime += delta
    if self.fireTime > self.fireInterval:
      self.createBullet(vec2(70.0, 0.0), self.bulletSpawnPoint.global_position)
      self.fireTime = 0