import godot
import godotapi / [sprite, input_event_mouse_button]
import hot
import strformat

gdobj SpriteComp of Sprite:

  signal clicked(button_idx:int, shape_idx:int)

  method enter_tree() =
    discard register(sprite_comp)
    discard self.connect("clicked", self, "on_clicked")

  method ready() =
    var area2D = self.get_node("Area2D")
    discard area2D.connect("input_event", self, "on_area2d_input_event")

  proc reload():seq[byte] {.gdExport.} =
    self.queue_free()

  proc on_clicked(button_idx:int, shape_idx:int) {.gdExport.} =
    print &"button:{button_idx} on shape: {shape_idx} clicked"

  proc on_area2d_input_event(viewport:Node, event:InputEvent, shape_idx:int) {.gdExport} =
    ifis(event, InputEventMouseButton):
      if it.pressed:
        self.emit_signal("clicked", (cast[int](it.button_index)).toVariant, shape_idx.toVariant)