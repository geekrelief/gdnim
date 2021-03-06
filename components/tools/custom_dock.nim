import gdnim, godotapi / [editor_plugin, resource_loader, packed_scene, control]


#[
WARNING: GDNative reloading of tool scripts is broken.
If you enable and disable the plugin, or unfocus the editor window while
the plugin is enabled which will cause the plugin to reload, you might
get a crash. You also might get warnings about leaked resources, when the
plugin is enabled while the editor is closed.

As a workaround, gdnlib's reloadable flag is set to false, so the
plugin will not reload when the editor is unfocused. To see your
changes, close the editor and reopen after compilation.
]#

gdobj(CustomDock of EditorPlugin, tool):
  var dock:Control

  method enter_tree() =
    self.dock = ((load("res://addons/custom_dock/custom_dock.tscn") as PackedScene).instance()) as Control
    self.add_control_to_dock(DOCK_SLOT_LEFT_UL, self.dock)

  method exit_tree() =
    self.remove_control_from_docks(self.dock)
    self.dock.queue_free()