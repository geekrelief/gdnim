import gdnim, godotapi / [editor_plugin, resource_loader, editor_interface, packed_scene, control, viewport]

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

gdobj(MainScreen of EditorPlugin, tool):

  var main_panel_instance:Control

  method enter_tree() =
    var main_screen = load("res://addons/main_screen/main_screen.tscn") as PackedScene
    self.main_panel_instance = main_screen.instance() as Control
    self.getEditorInterface().getEditorViewport().addChild(self.main_panel_instance)
    self.make_visible(false)

  method exit_tree() =
    if self.main_panel_instance != nil:
      self.main_panel_instance.queueFree()

  # EditorPlugin.has_main_screen is virtual, but if we define it as a method
  # gdobj will prepend an underscore and godot won't find it
  # define virtual with gdExport pragma so the name is exported as is
  method hasMainScreen():bool {.gdExport.} =
    true

  method makeVisible(visible:bool) {.gdExport.} =
    if not self.main_panel_instance.isNil:
      self.main_panel_instance.visible = visible

  method getPluginName():string {.gdExport.} =
    "Main Screen"

  method getPluginIcon():Texture {.gdExport.} =
    self.get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")