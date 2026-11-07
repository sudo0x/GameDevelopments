extends SceneTree
## One project-wide theme styles every menu, so no default Godot look is left in them.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var theme: Theme = load("res://data/ui/game_theme.tres")
	check("the project uses it", ProjectSettings.get_setting("gui/theme/custom") == "res://data/ui/game_theme.tres")
	for style in ["normal", "hover", "pressed", "disabled", "focus"]:
		check("buttons have a %s look" % style, theme.has_stylebox(style, "Button"))
	check("panels", theme.has_stylebox("panel", "PanelContainer"))
	for style in ["normal_joystick", "normal_tip", "pressed_joystick", "pressed_tip"]:
		check("joystick " + style, theme.has_stylebox(style, "VirtualJoystick"))
	check("the pixel font is the default", theme.default_font != null and theme.default_font.resource_path.ends_with("m5x7.ttf"))
	check("drawn crisp, with no smoothing", (theme.default_font as FontFile).antialiasing == TextServer.FONT_ANTIALIASING_NONE)
	check("the size is a clean size", theme.default_font_size == 24)
	check("panels are art", theme.get_stylebox("panel", "PanelContainer") is StyleBoxTexture)
	check("buttons are art", theme.get_stylebox("normal", "Button") is StyleBoxTexture)
	for crop in inv.CROPS:
		check(crop.id + " has icons", crop.icon != null and crop.seed_icon != null)
	for material in inv.MATERIALS:
		check(material.id + " has an icon", material.icon != null)
	for recipe in inv.RECIPES:
		check(recipe.display_name + " has an icon", recipe.icon != null)
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for path in ["HUD/ShopMenu", "HUD/BagMenu", "HUD/CraftingMenu"]:
		var menu: Control = main.get_node(path)
		check(path + " panel comes from the theme", menu.get_theme_stylebox("panel") == theme.get_stylebox("panel", "PanelContainer"))
	var shop: Control = main.get_node("HUD/ShopMenu")
	check("shop buttons too", shop._buttons[0].get_theme_stylebox("normal") == theme.get_stylebox("normal", "Button"))
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
