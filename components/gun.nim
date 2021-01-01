import godot
import godotapi/[sprite, scene_tree, packed_scene, resource_loader, node_2d]
import hot
import tables
import strformat
import sequtils
import macros

gdobj Gun of Sprite:

  var bulletResPath:string
  var bulletRes:PackedScene
  var bulletSpawnPoint:Node2D

  var nextBulletId:int64
  var bullets:Table[int64, Node]
  var fireTime:float64
  var fireInterval:float64 = 0.02

  method enter_tree() =
    self.bulletResPath = findCompTscn("bullet")
    var button_fireSingle = self.get_parent().get_node("Button_FireSingle")
    discard button_fireSingle.connect("pressed", self, "fire_single")

    self.bulletSpawnPoint = self.get_node("BulletSpawnPoint") as Node2D
    register(gun)?.load(self.nextBulletId, self.position)
    self.setupBullets()

  method exit_tree() =
    self.bulletRes = nil

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()
    save(self.nextBulletId, self.position)

  proc setupBullets(bulletData:seq[byte] = @[]) {.gdExport.} =
    self.bulletRes = resource_loader.load(self.bulletResPath) as PackedScene

    var pathv = $self.get_path()
    withSome register(bullet, pathv, save_bullets, setup_bullets):
      some bb:
        var count:int
        bb.unpack(count)
        if count == 0: return
        for i in 0..<count:
          var bdata:seq[byte]
          bb.unpack(bdata)
          var bullet = self.bulletRes.instance()
          var vid = bullet.call("unpack_data", bdata.toVariant)
          var bid:int64 = vid.asInt
          discard bullet.connect("dead", self, "bullet_dead")
          self.get_tree().root.add_child(bullet)
          self.bullets[bid] = bullet

  proc saveBullets():seq[byte] {.gdExport.} =
    #destroy any existing bullets
    var ms = MsgStream.init()
    ms.pack(self.bullets.len)
    var keys = toSeq(self.bullets.keys)
    for id in keys:
      var b = self.bullets[id]
      b.disconnect("dead", self, "bullet_dead")
      var bv = b.call("pack_data")
      var bdata:seq[byte]
      discard fromVariant(bdata, bv)
      ms.pack(bdata)
      self.bullet_dead(id)
    self.bulletRes = nil

    result = cast[seq[byte]](ms.data)

  proc createBullet(v:Vector2, p:Vector2) =
    if self.bulletRes == nil: return
    var id = self.nextBulletId
    inc self.nextBulletId
    var b = self.bulletRes.instance()
    b.call_deferred("set_data", id.toVariant, v.toVariant, p.toVariant)
    discard b.connect("dead", self, "bullet_dead")
    self.get_tree().root.add_child(b)
    self.bullets[id] = b

  proc bullet_dead(id:int64) {.gdExport.} =
    if self.bullets.hasKey(id):
      var b = self.bullets[id]
      b.queue_free()
      self.bullets.del(id)

  proc fireSingle() {.gdExport.} =
    for i in 0..10:
      self.createBullet(vec2(120.0 + i.toFloat * 6.0,0.0), self.bulletSpawnPoint.global_position)

  method process(delta:float64) =
    self.fireTime += delta
    if self.fireTime > self.fireInterval:
      self.createBullet(vec2(320.0, 0.0), self.bulletSpawnPoint.global_position)
      self.fireTime = 0
