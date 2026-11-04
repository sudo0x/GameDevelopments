extends SceneTree
## The bag shows everything the player owns, pauses the game, and keeps materials in the save.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await physics_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	Input.flush_buffered_events()
	await physics_frame


func cells(bag: Node) -> Array:
	return bag.crops_grid.get_children().map(func(n: Label) -> String: return n.text)


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var bag: Control = main.get_node("HUD/BagMenu")
	var shop: Control = main.get_node("HUD/ShopMenu")
	var hud: Node = main.get_node("HUD")
	var player: Node = main.get_node("World/Player")
	var wood = gs.MATERIALS[0]
	var stone = gs.MATERIALS[1]
	var key := InputEventKey.new()
	key.physical_keycode = KEY_I
	key.pressed = true
	check("physical I maps to inventory", key.is_action_pressed("inventory"))
	check("starts closed", not bag.visible)
	check("HUD no longer lists crops", not hud.status_label.text.contains("Radish"))

	gs.add_material(wood, 3)
	gs.add_material(stone, 2)
	gs.add_material(wood, 1)
	check("materials add up", gs.material_count(wood) == 4 and gs.material_count(stone) == 2)
	gs.harvest[&"carrot"] = 7
	gs.holy_water = 2
	await press("inventory")
	check("opens and pauses", bag.visible and paused)
	var list := cells(bag)
	print(list)
	check("crop table", list == ["", "Harvested", "Seeds", "Radish", "0", "10", "Carrot", "7", "5", "Pumpkin", "0", "3"])
	check("items", bag.items_label.text == "Holy water: 2\nWood: 4\nStone: 2\nCurse shard: 0")
	var pos: Vector2 = player.global_position
	Input.action_press("move_left")
	for i in 20:
		await physics_frame
	Input.action_release("move_left")
	check("player can't move while open", player.global_position == pos)
	gs.add_material(stone, 1)
	check("updates while open", bag.items_label.text.contains("Stone: 3"))
	await press("inventory")
	check("I closes", not bag.visible and not paused)
	await press("inventory")
	await press("ui_cancel")
	check("Esc closes", not bag.visible and not paused)
	await physics_frame
	check("stays closed", not bag.visible)
	gs.holy_water = 0
	gs.add_material(wood, 1)
	await press("inventory")
	check("fresh numbers when reopened", bag.items_label.text.contains("Wood: 5"))
	await press("inventory")

	# Only one menu at a time.
	shop.open()
	await press("inventory")
	check("bag won't open over the shop", not bag.visible and shop.visible)
	shop.close()
	check("game unpaused after shop", not paused)

	# Materials are saved.
	gs.save_game()
	gs.materials.clear()
	gs.load_game()
	check("materials saved", gs.material_count(wood) == 5 and gs.material_count(stone) == 3)
	check("keys still StringName", typeof(gs.materials.keys()[0]) == TYPE_STRING_NAME)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
