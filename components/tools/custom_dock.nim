import gdnim, godotapi / [editor_plugin, resource_loader, packed_scene, control]

gdobj(CustomDock of EditorPlugin, tool):
  #[
  proc hot_unload():seq[byte] {.gdExport.} =
    self.queue_free()
    #save()
  ]#
  var dock:Control

  method enter_tree() =
    self.dock = ((load("res://addons/custom_dock/custom_dock.tscn") as PackedScene).instance()) as Control
    self.add_control_to_dock(DOCK_SLOT_LEFT_UL, self.dock)

  method exit_tree() =
    self.remove_control_from_docks(self.dock)
    self.dock.queue_free()