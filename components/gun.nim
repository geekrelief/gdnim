import godot, godotapi/[sprite, scene_tree, packed_scene, resource_loader, node_2d]
import gdnim
import tables
import strformat
import sequtils

gdobj Gun of Sprite:

  var bulletRes:PackedScene
  var bulletSpawnPoint:Node2D

  var nextBulletId:int64
  var fireTime:float64
  var fireInterval:float64 = 0.3

  method enter_tree() =
    register(gun)?.load(self.nextBulletId, self.position)
    # gun needs to register bullet as a dependency
    register_dependencies(gun, bullet)

    self.bulletSpawnPoint = self.get_node("BulletSpawnPoint") as Node2D
    self.bulletRes = resource_loader.load(findCompTscn("bullet")) as PackedScene

    var button_fireSingle = self.get_parent().get_node("Button_FireSingle")
    discard button_fireSingle.connect("pressed", self, "fire_single")

  method exit_tree() =
    self.bulletRes = nil

  proc hot_unload():seq[byte] {.gdExport.} =
    self.queue_free()
    self.bulletRes = nil
    save(self.nextBulletId, self.position)

  proc hot_depreload(compName:string, isUnloading:bool) {.gdExport.} =
    case compName:
      of "bullet":
        if isUnloading:
          self.bulletRes = nil # free the reference or the dll can't unload
        else:
          self.bulletRes = resource_loader.load(findCompTscn("bullet")) as PackedScene

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