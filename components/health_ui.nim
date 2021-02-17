import gdnim, godotapi / [control, texture_rect]
import strformat

gdobj HealthUi of Control:
  var health {.gdExport, set:"set_health".}:int
  var hearts:TextureRect

  proc set_health(value:int) =
    self.health = max(0, value)
    if not self.hearts.isNil:
      self.hearts.rect_size = vec2(18 * float(self.health), 16)

  proc hot_unload():seq[byte] {.gdExport.} =
    self.queue_free()
    save(self.rect_position)

  method enter_tree() =
    register(health_ui)?.load(self.rect_position)

  method ready() =
    self.hearts = self.get_node("Hearts") as TextureRect
    self.set_health(self.health)
