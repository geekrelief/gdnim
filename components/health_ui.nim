import gdnim
import strformat

gdnim HealthUi of Control:
  # health is updateable from the Local inspector while running,
  # Remote inspector doesn't work cause Godot is using a PlaceholderScript
  var health {.gdExport, set:"set_health".}:int
  var hearts:TextureRect

  unload:
    self.queue_free()
    save(self.rect_position)

  reload:
    load(self.rect_position)

  proc set_health(value:int) =
    self.health = max(0, value)
    if not self.hearts.isNil:
      self.hearts.rect_size = vec2(18 * float(self.health), 16)

  method ready() =
    self.hearts = self.get_node("Hearts") as TextureRect
    self.set_health(self.health)