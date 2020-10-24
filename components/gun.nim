import godot
import godotapi/[sprite, scene_tree, packed_scene, resource_loader, node_2d]
import hot
import tables
import strformat

gdobj Gun of Sprite:

  var compName = "gun"
  var bulletResPath = "res://bullet.tscn"
  var bulletRes:PackedScene

  var button_fireSingle:Node
  var bulletSpawnPoint:Node2D

  var bulletId:int
  var bullets:Table[string, Node]

  method enter_tree() =
    var button_fireSingle = self.get_parent().get_node("Button_FireSingle")
    self.button_fireSingle = button_fireSingle
    if button_fireSingle.isNil:
      print "wtf"
    if button_fireSingle != nil:
      print "got the Button_FireSingle"
    discard button_fireSingle.connect("pressed", self, "fire_single")

    self.bulletSpawnPoint = self.get_node("BulletSpawnPoint") as Node2D
    self.setupBullet()

  method exit_tree() =
    self.bulletRes = nil

  proc reload():seq[byte] =
    self.queue_free()
    # don't save anything for now

  proc setupBullet() {.gdExport.} =
    print "gun: setupBullet"
    self.bulletRes = resource_loader.load(self.bulletResPath) as PackedScene

    var pathv = ($self.get_path()).toVariant
    var w = self.get_node("/root/Watcher")
    if w.isNil:
      raise newException(Defect, "Watcher not found")

    var bv = w.call("register_component",
      "bullet".toVariant,
      pathv, #savePath
      pathv, #loadPath,
      "save_bullets".toVariant,
      "setup_bullet".toVariant
    )
    var data:seq[byte]
    discard fromVariant(data, bv)
    if data.len == 0: return
    var b = MsgStream.init(cast[string](data))
    var count:int
    b.unpack(count)
    if count == 0:
      return
    for i in 0..<count:
      # get bullet velocity and position
      var barr:array[4, float]
      b.unpack(barr)
      self.createBullet(vec2(barr[0], barr[1]), vec2(barr[2], barr[3]))

  proc saveBullets():seq[byte] {.gdExport.} =
    print "gun: bullet reload"
    #destroy any existing bullets
    var bullets = self.bullets
    for id, b in bullets:
      self.bullet_dead(id)
    self.bulletRes = nil

    result


  proc createBullet(v:Vector2, p:Vector2) =
    var b = self.bulletRes.instance()
    var id = self.bulletId
    inc self.bulletId
    b.call_deferred("set_data", ($id).toVariant, v.toVariant, p.toVariant)
    discard b.connect("dead", self, "bullet_dead")
    self.get_tree().root.add_child(b)
    self.bullets[$id] = b

  proc bullet_dead(id:string) {.gdExport.} =
    print &"gun got {id} is dead"

    if self.bullets.hasKey(id):
      var b = self.bullets[id]
      b.disconnect("dead", self, "bullet_dead")
      b.queue_free()
      self.bullets.del(id)

  proc fireSingle() {.gdExport.} =
    print "fire single"
    self.createBullet(vec2(1.0,0.0), self.bulletSpawnPoint.global_position)