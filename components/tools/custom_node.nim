import godot, godotapi / [editor_plugin, resource_loader]

gdobj(CustomNode of EditorPlugin, tool):

  method enter_tree() =
    var script = load("res://_gdns/my_button.gdns") as Script
    var icon = load("res://addons/custom_node/icon.png") as Texture
    var scene = load("res://_tscn/my_button.tscn") as PackedScene
    self.addCustomType("MyButton", "Button", script, icon, scene)

  method exit_tree() =
    self.removeCustomType("MyButton")