import godot
import godotapi / [sprite, input_event_mouse_button, scene_tree]
import hot
import strformat
import math

gdobj SpriteComp of Sprite:
  var startPos:Vector2 = vec2(100.0, 100.0)
  var radius:float = 110.0
  var speed:float = 0.05
  var elapsedTime:float

  signal clicked(button_idx:int, shape_idx:int)

  method enter_tree() =
    discard register(sprite_comp)
    self.position = self.startPos

  method ready() =
    var area2D = self.get_node("Area2D")
    discard area2D.connect("input_event", self, "on_area2d_input_event")
    discard self.connect("clicked", self, "on_clicked")

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()

  proc on_area2d_input_event(viewport:Node, event:InputEvent, shape_idx:int) {.gdExport.} =
    ifis(event, InputEventMouseButton):
      if it.pressed:
        self.emit_signal("clicked", it.button_index.toVariant, shape_idx.toVariant)
        self.get_tree().set_input_as_handled()

  proc on_clicked(button_idx:int, shape_idx:int) {.gdExport.} =
    print &"{button_idx = } clicked {shape_idx = }"

  method process(delta:float64) =
    self.elapsedTime += delta
    var angle = self.elapsedTime * TAU * self.speed
    self.position = self.startPos + self.radius * vec2(cos(angle), sin(angle))