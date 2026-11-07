extends SceneTree
## Crafting the sword, and swinging it at a stand-in target.
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


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


## A body that counts hits, standing in for a creature until step 3.
func make_dummy() -> StaticBody2D:
	var script := GDScript.new()
	script.source_code = "extends StaticBody2D\nvar hits := 0\nvar pushed := Vector2.ZERO\nfunc take_hit(damage: int, direction: Vector2) -> void:\n\thits += damage\n\tpushed = direction\n"
	script.reload()
	var dummy := StaticBody2D.new()
	dummy.set_script(script)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	dummy.add_child(shape)
	return dummy


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var inv: Node = root.get_node("Inventory")
	var saves: Node = root.get_node("SaveGame")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var farm: Node = main.get_node("Farm")
	var hud: Node = main.get_node("HUD")
	var player: Node = main.get_node("World/Player")
	var sword: Node2D = player.get_node("Sword")
	var menu: Node = main.get_node("HUD/CraftingMenu")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_7
	key.pressed = true
	check("physical 7 maps to tool_7", key.is_action_pressed("tool_7"))

	var body_y := Vector2(0, -20)
	player.global_position = Vector2(600, 500)
	var dummy := make_dummy()
	main.get_node("World").add_child(dummy)
	dummy.global_position = player.global_position + body_y + Vector2(30, 0)
	player.facing = 3
	await wait(3)

	# No sword yet.
	await press("tool_7")
	check("selected", player.tool == 6)
	check("label says how to get one", hud.tool_label.text == "Tool: Sword  |  Craft one at the workbench")
	await wait(2)
	check("no highlight with the sword", not farm.highlight.visible)
	await press("use_tool")
	await wait(12)
	check("no swing without it", dummy.hits == 0)

	# Crafting it, once only.
	var recipe = inv.RECIPES[5]
	inv.add_material(inv.MATERIALS[0], 5)
	inv.add_material(inv.MATERIALS[1], 3)
	gs.request_crafting()
	await process_frame
	check("in the menu", menu._labels[5].text == "Sword\n5 Wood (5), 3 Stone (3)")
	menu._buttons[5].pressed.emit()
	check("made", inv.has_sword and inv.material_count(inv.MATERIALS[0]) == 0)
	check("done text", menu._labels[5].text == "Sword\nPress 7, then Space to swing." and menu._buttons[5].text == "Made")
	check("hoe text comes from data", inv.RECIPES[1].made_text == "Use the hoe on cursed land.")
	check("only once", not inv.can_craft(recipe))
	menu.close()
	check("label clears", hud.tool_label.text == "Tool: Sword")
	await wait(2)

	# Hitting.
	await press("use_tool")
	check("blade out", sword.blade.visible)
	await wait(14)
	check("one hit", dummy.hits == 1)
	check("direction passed on", dummy.pushed == Vector2.RIGHT)
	check("blade away after", not sword.blade.visible)
	await wait(12)

	# Mashing can't beat the cooldown.
	var before: int = dummy.hits
	for i in 8:
		await press("use_tool")
	await wait(16)
	check("mashing for 16 frames gives one hit", dummy.hits == before + 1)
	await wait(12)

	# Only what's in front.
	player.facing = 2
	before = dummy.hits
	await press("use_tool")
	await wait(30)
	check("swinging away misses", dummy.hits == before)
	check("no error on things that can't be hit", player.tool == 6)
	player.facing = 3
	dummy.global_position = player.global_position + body_y + Vector2(120, 0)
	await wait(3)
	await press("use_tool")
	await wait(30)
	check("too far away misses", dummy.hits == before)

	# Every direction reaches.
	for facing in 4:
		player.facing = facing
		dummy.global_position = player.global_position + body_y + player.FACING_DIRECTIONS[facing] * 30.0
		await wait(3)
		before = dummy.hits
		await press("use_tool")
		await wait(30)
		check("hits in direction %d" % facing, dummy.hits == before + 1)
	player.facing = 1
	await press("use_tool")
	check("behind the player facing up", sword.blade.show_behind_parent)
	await wait(30)

	# Other tools don't swing, and the sword doesn't touch the farm.
	await press("tool_4")
	before = dummy.hits
	await press("use_tool")
	check("hand doesn't swing", not sword.blade.visible)
	await press("tool_7")
	check("sword does nothing to a tile", not farm.can_use(6, Vector2i(16, 12)))

	# Saved.
	saves.save_game()
	inv.has_sword = false
	saves.load_game()
	check("saved", inv.has_sword)
	var bag: Node = main.get_node("HUD/BagMenu")
	bag.open()
	check("bag shows it", bag.items_text.contains("Sword"))
	bag.close()
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)

