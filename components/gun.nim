import godot
import godotapi/[sprite, scene_tree, packed_scene, resource_loader, node_2d]
import hot
import tables
import strformat
import sequtils
import macros

gdobj Gun of Sprite:

  var compName = "gun"
  var bulletResPath = "res://bullet.tscn"
  var bulletRes:PackedScene

  var button_fireSingle:Node
  var bulletSpawnPoint:Node2D

  var bulletId:int64
  var bullets:Table[int64, Node]

  method enter_tree() =
    print "gun: enter_tree"
    var button_fireSingle = self.get_parent().get_node("Button_FireSingle")
    self.button_fireSingle = button_fireSingle
    discard button_fireSingle.connect("pressed", self, "fire_single")

    self.bulletSpawnPoint = self.get_node("BulletSpawnPoint") as Node2D
    register(gun)?.load(self.bulletId, self.position)
    self.setupBullets()

  method exit_tree() =
    self.bulletRes = nil

  proc reload():seq[byte] {.gdExport.} =
    print "gun: reload save"
    self.queue_free()
    save(self.bulletId, self.position)

  proc setupBullets(bulletData:seq[byte] = @[]) {.gdExport.} =
    print "gun: setupBullets"
    self.bulletRes = resource_loader.load(self.bulletResPath) as PackedScene

    var pathv = $self.get_path()
    withSome register(bullet, pathv, pathv, save_bullets, setup_bullets):
      some bb:
        var count:int
        bb.unpack(count)
        if count == 0: return
        print &"gun: got {count} bullets"
        for i in 0..<count:
          var bdata:seq[byte]
          bb.unpack(bdata)
          var bullet = self.bulletRes.instance()
          var vid = bullet.call("unpack_data", bdata.toVariant)
          var bid:int64 = vid.asInt
          print &"gun: reload bullet {bid}"
          discard bullet.connect("dead", self, "bullet_dead")
          self.get_tree().root.add_child(bullet)
          self.bullets[bid] = bullet

  proc saveBullets():seq[byte] {.gdExport.} =
    print "gun: saveBullets"
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
    if self.bullets.hasKey(8):
      print "\t-- has 8!!"
    print self.bullets.len
    self.bulletRes = nil

    result = cast[seq[byte]](ms.data)


  proc createBullet(v:Vector2, p:Vector2) =
    var id = self.bulletId
    inc self.bulletId
    print &"gun: createBullet {id}"
    var b = self.bulletRes.instance()
    b.call_deferred("set_data", id.toVariant, v.toVariant, p.toVariant)
    discard b.connect("dead", self, "bullet_dead")
    self.get_tree().root.add_child(b)
    self.bullets[id] = b

  proc bullet_dead(id:int64) {.gdExport.} =
    if self.bullets.hasKey(id):
      print &"gun: dead bullet {id}"
      var b = self.bullets[id]
      b.queue_free()
      self.bullets.del(id)
    else:
      print &"gun: bullet no key {id}"

  proc fireSingle() {.gdExport.} =
    self.createBullet(vec2(0.2,0.0), self.bulletSpawnPoint.global_position)