import gdnim, godotapi / [editor_plugin, resource_loader, editor_interface, packed_scene, control, viewport]

#The scene doesn't appear
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
  # define virtual without underscore as a proc and add gdExport pragma
  proc hasMainScreen():bool {.gdExport.} =
    true

  proc makeVisible(visible:bool) {.gdExport.} =
    if not self.main_panel_instance.isNil:
      self.main_panel_instance.visible = visible

  proc getPluginName():string {.gdExport.} =
    "Main Screen"

  proc getPluginIcon():Texture {.gdExport.} =
    self.get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")