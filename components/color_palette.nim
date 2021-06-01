import gdnim, godotapi / [h_box_container, packed_scene, tween, color_picker]
import std / strformat

gdnim ColorPalette of HBoxContainer:

  var
    colors: seq[Color] = @[
      initColor(1.0, 1.0, 0.0),
      initColor(1.0, 0.0, 1.0),
      initColor(0.0, 1.0, 1.0),
    ]
  var colorPicker: ColorPicker
  var curSlot: Node # this may hold a reference to a color_palette_slot so we need to define it as a dependency

  dependencies:
    color_palette_slot # if color_palette_slot is reloaded, this ensures self.curSlot is cleared

  unload:
    save()

  reload:
    load()

  method enter_tree() =
    if self.isNewInstance():
      var colorPaletteSlotRes = loadScene("color_palette_slot")
      ifValid colorPaletteSlotRes:
        for c in self.colors:
          var slot = colorPaletteSlotRes.instance()
          slot.setImpl("color", c.toVariant())
          self.addChild(slot)

    #print "reconnect to slots" # connect needs to happen on enter_tree, on ready is too late
    for i in 0..<self.getChildCount:
      var slot = self.getChild(i)
      discard slot.connect("doubleclick", self, "edit_slot")
      discard slot.connect("selected", self, "select_slot")

    self.colorPicker = self.getTree().root.findNode("ColorPicker", true, false) as ColorPicker
    ifValid self.colorPicker:
      discard self.colorPicker.connect("color_changed", self, "on_color_changed")

  proc on_color_changed(c: Color) {.gdExport.} =
    ifValid self.curSlot:
      self.curSlot.setImpl("color", c.toVariant())

  proc edit_slot(slot: Node) {.gdExport.} =
    ifValid self.colorPicker:
      self.colorPicker.visible = not self.colorPicker.visible

  proc select_slot(slot: Node) {.gdExport.} =
    ifValid self.colorPicker:
      self.colorPicker.color = slot.getImpl("color").asColor()

    self.curSlot = slot
    var count = self.getChildCount()
    for i in 0..<count:
      var child = self.getChild(i)
      if child != slot:
        child.setImpl("is_selected", false.toVariant)