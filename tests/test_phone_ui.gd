extends SceneTree
## On a touch screen, nothing should mention keys, and buttons must suit a thumb.
var fails := 0
const KEY_WORDS: Array[String] = ["Space", "Enter", "Esc", "Q / E", "F /", "I /", "Press", "press", "Arrows"]


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func no_keys(name: String, text: String) -> void:
	var clean := not text.is_empty()
	for word in KEY_WORDS:
		clean = clean and not text.contains(word)
	check(name + ": " + text.replace("\n", " / "), clean)


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var farm: Node = main.get_node("Farm")
	var hud: Node = main.get_node("HUD")
	var controls: Node2D = main.get_node("HUD/TouchControls")
	var player: Node2D = main.get_node("World/Player")
	var shop: Control = main.get_node("HUD/ShopMenu")
	var bag: Control = main.get_node("HUD/BagMenu")
	var craft: Control = main.get_node("HUD/CraftingMenu")
	check("keyboard text by default", hud.tool_label.text == "Tool: Hoe" and not gs.touch_mode)
	controls.set_active(true)
	await wait(2)
	check("touch mode on", gs.touch_mode)

	# The tool bar uses art.
	for i in 7:
		var button: Node2D = controls._tool_buttons[i]
		var icons := button.get_children().filter(func(n: Node) -> bool: return n is Sprite2D)
		check("tool %d has an icon" % (i + 1), icons.size() == 1 and icons[0].texture != null)
		check("tool %d has no word" % (i + 1), button.get_children().filter(func(n: Node) -> bool: return n is Label).is_empty())
	var hoe: Sprite2D = controls._tool_buttons[0].get_child(0)
	var can: Sprite2D = controls._tool_buttons[1].get_child(0)
	check("each icon is its own picture", hoe.texture.region != can.texture.region)
	check("the watering can isn't cut off", can.texture.region.size.x == 36.0)

	# Tool help.
	gs.strong_holy_water = 1
	player.tool = 2
	player.tool_changed.emit()
	no_keys("seeds", hud.tool_label.text)
	check("names the buttons", hud.tool_label.text.contains("< >"))
	player.tool = 4
	player.tool_changed.emit()
	no_keys("holy water", hud.tool_label.text)
	player.strong_water = true
	player.tool_changed.emit()
	no_keys("strong holy water", hud.tool_label.text)
	player.tool = 5
	player.tool_changed.emit()
	no_keys("build", hud.tool_label.text)

	# Help from the world.
	no_keys("gathering", farm.gathering.status(Vector2i(22, 6)))
	var cell := Vector2i(16, 12)
	farm.till(cell)
	farm.plant(cell, gs.CROPS[0])
	farm.crops[cell].set_days_grown(3)
	no_keys("ripe crop", farm.crop_status(cell))
	gs.buildings[&"fence"] = 1
	farm.builder.place(Vector2i(16, 14), gs.building_by_id(&"fence"))
	no_keys("placed building", farm.builder.status(Vector2i(16, 14)))

	# Menus. They must never cover the button that closes them.
	var act: Dictionary = {}
	for entry in controls.ACTION_BUTTONS:
		if entry[1] == "interact":
			act = {"center": entry[2], "size": entry[3]}
	var act_left: float = act["center"].x - act["size"] / 2.0
	shop.open()
	await process_frame
	no_keys("shop help", shop.get_node("Margin/Box/Help").text)
	for button: Button in shop._buttons:
		check("shop button fits a thumb", button.size.y >= 34.0)
	check("the shop fits the screen", shop.get_global_rect().size.y <= 360.0 and shop.get_global_rect().position.y >= 0.0)
	check("the shop leaves Act showing", shop.get_global_rect().end.x <= act_left)
	shop.close()
	bag.open()
	await process_frame
	no_keys("bag help", bag.get_node("Margin/Box/Help").text)
	bag.close()
	# The fullest bag a player can have.
	gs.has_sword = true
	gs.has_purifying_hoe = true
	gs.strong_holy_water = 99
	gs.holy_water = 99
	gs.harvest[&"pumpkin"] = 999
	for material in gs.MATERIALS:
		gs.materials[material.id] = 999
	for building in gs.BUILDINGS:
		gs.buildings[building.id] = 99
	bag.open()
	await process_frame
	await process_frame
	print("full bag ", bag.get_global_rect())
	check("a full bag fits the screen", bag.get_global_rect().size.y <= 360.0 and bag.get_global_rect().position.y >= 0.0)
	check("a full bag leaves Act showing", bag.get_global_rect().end.x <= act_left)
	bag.close()
	gs.has_sword = true
	craft.open()
	await process_frame
	no_keys("crafting help", craft.get_node("Margin/Box/Help").text)
	no_keys("made sword", craft._labels[5].text)
	for button: Button in craft._buttons:
		check("crafting button fits a thumb", button.size.y >= 34.0)
	check("the workbench fits the screen", craft.get_global_rect().size.y <= 360.0 and craft.get_global_rect().position.y >= 0.0)
	print("workbench right edge ", craft.get_global_rect().end.x, ", Act left edge ", act_left)
	check("the workbench leaves Act showing", craft.get_global_rect().end.x <= act_left)
	craft.close()

	# Nothing tappable sits under a menu, except what closes it.
	craft.open()
	await wait(2)
	var bar: Node2D = controls.get_node("ToolBar")
	# 7 tools, < and >, and pause.
	check("tool bar, < > and pause hide under a menu", not bar.visible and bar.get_child_count() == 10)
	craft.close()
	await wait(2)

	# Back to a keyboard.
	controls.set_active(false)
	await wait(2)
	player.tool = 2
	player.tool_changed.emit()
	check("keyboard words return", hud.tool_label.text.contains("Q / E"))
	shop.open()
	await process_frame
	check("menus too", shop.get_node("Margin/Box/Help").text.contains("Enter"))
	check("centered again on a computer", is_equal_approx(shop.get_global_rect().get_center().x, 320.0))
	shop.close()

	# The title screen's buttons.
	var title: Control = load("res://scenes/ui/title_screen.tscn").instantiate()
	main.free()
	root.add_child(title)
	await process_frame
	await process_frame
	check("title buttons fit a thumb", title.new_game_button.size.y >= 34.0)
	check("title fits the screen", title.get_node("Center/Box").get_global_rect().size.y <= 360.0)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
