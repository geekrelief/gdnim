import gdnim, godotapi / [v_box_container, input_event_mouse_button, tween]
import std / strformat

gdnim ColorPaletteSlot of VBoxContainer:
  var selectTweenTime: float = 0.25
  var colorTweenTime: float = 0.5

  signal doubleclick(node: Node)
  signal selected(node: Node)

  var
    color {.gdExport, set: "set_color".}: Color
    colorRect: ColorRect
    isSelected {.gdExport, set: "set_selected".}: bool
    selectedArrow: CanvasItem
    tween: Tween

  unload:
    save()

  reload:
    load()

  method ready() =
    self.colorRect = self.getNode("ColorRect") as ColorRect
    self.selectedArrow = self.getNode("CenterContainer/SelectedArrow") as CanvasItem
    self.tween = self.getNode("Tween") as Tween
    self.set_color(self.color)
    self.set_selected(self.isSelected)

  method gui_input(e: InputEvent) =
    ifis(e, InputEventMouseButton):
      if it.doubleclick:
        toV self.emitSignal("doubleclick", [self])
      elif it.pressed:
        self.set_selected(true)

  proc set_color(c: Color) =
    self.color = c
    ifValid self.colorRect, self.tween:
      discard self.tween.seek(self.tween.getRunTime())
      discard self.tween.interpolateProperty(self.colorRect, "color", self.colorRect.color.toVariant(), self.color.toVariant(), self.colorTweenTime, TRANS_CUBIC, EASE_OUT)
      discard self.tween.interpolateProperty(self.colorRect, "rect_rotation", self.colorRect.rect_rotation.toVariant(),
        (self.colorRect.rect_rotation + 180.0).toVariant(), self.colorTweenTime, TRANS_CUBIC, EASE_OUT)
      discard self.tween.start()

  proc set_selected(state: bool) {.gdExport.} =
    self.isSelected = state
    if self.isSelected:
      toV self.emitSignal("selected", [self])
    ifValid self.selectedArrow:
      self.selectedArrow.visible = state

    ifValid self.tween:
      discard self.tween.seek(self.tween.getRunTime())

      if self.isSelected:
        var tPos = vec2(self.colorRect.rectPosition.x, self.colorRect.rectPosition.y+5)
        discard self.tween.interpolateProperty(self.colorRect, "rect_position", self.colorRect.rectPosition.toVariant(), tPos.toVariant(), self.selectTweenTime, TRANS_CUBIC, EASE_OUT)
        discard self.tween.interpolateProperty(self.colorRect, "rect_position", tPos.toVariant(), self.colorRect.rectPosition.toVariant(), self.selectTweenTime, TRANS_CUBIC, EASE_OUT, self.selectTweenTime)
        discard self.tween.start()