extends SceneTree
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
func _initialize() -> void:
	_run()
func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var player: Node = main.get_node("World/Player")
	var hud: Node = main.get_node("HUD")
	var menu: Node = main.get_node("HUD/ShopMenu")
	var stall: Node2D = main.get_node("World/ShopStall")
	var CURSED := 1

	# Key 5 from a real key event, not only the action.
	var k := InputEventKey.new()
	k.physical_keycode = KEY_5
	k.pressed = true
	check("physical 5 maps to tool_5", k.is_action_pressed("tool_5"))
	await press("tool_5")
	check("key 5 selects holy water", player.tool == 4)
	check("tool label", hud.tool_label.text == "Tool: Holy water: 0")

	# Buying at the stall.
	gs.money = 70
	player.global_position = stall.global_position + Vector2(0, 16)
	for i in 6:
		await physics_frame
	await press("interact")
	check("shop open", menu.visible)
	check("4 rows", menu._buttons.size() == 4)
	check("holy row text", menu._labels[3].text == "Holy water: 0" and menu._buttons[3].text == "Buy for 30")
	menu._buttons[3].pressed.emit()
	menu._buttons[3].pressed.emit()
	check("bought 2", gs.holy_water == 2 and gs.money == 10)
	check("button disabled when too poor", menu._buttons[3].disabled)
	menu._buttons[3].pressed.emit()
	check("third refused", gs.holy_water == 2 and gs.money == 10)
	check("seed row 0 still buys seeds", menu._labels[0].text.begins_with("Radish seeds"))
	await press("interact")
	check("shop closed", not menu.visible)
	check("HUD shows holy water", hud.inventory_label.text.contains("Holy water: 2"))

	# Walk to the east edge of the shore, then heal what's ahead.
	player.global_position = g.to_global(g.map_to_local(Vector2i(33, 13)))
	Input.action_press("move_right")
	for i in 200:
		await physics_frame
	Input.action_release("move_right")
	for i in 4:
		await physics_frame
	var feet: Vector2i = g.local_to_map(g.to_local(player.global_position + Vector2(0, -4)))
	var target: Vector2i = farm.target_cell
	print("feet ", feet, " target ", target, " cursed in patch: ", farm.healing.cleansable_cells(target).size())
	check("target is cursed", g.get_cell_source_id(target) == CURSED)
	var patch: Array = farm.healing.cleansable_cells(target)
	var x0: float = player.global_position.x
	await press("use_tool")
	check("one use spent", gs.holy_water == 1)
	var all_clean := true
	for c: Vector2i in patch:
		all_clean = all_clean and g.get_cell_source_id(c) == 0
	check("patch healed", all_clean and not patch.is_empty())
	check("texture piece lines up", g.get_cell_atlas_coords(target) == Vector2i(posmod(target.x, 4), posmod(target.y, 4)))
	Input.action_press("move_right")
	for i in 40:
		await physics_frame
	Input.action_release("move_right")
	check("can now walk onto healed land", player.global_position.x > x0 + 20)

	# Nothing to heal: must not spend.
	player.global_position = g.to_global(g.map_to_local(Vector2i(20, 13)))
	for i in 4:
		await physics_frame
	await press("use_tool")
	check("no cost on clean land", gs.holy_water == 1)
	check("highlight invalid on clean land", not farm.can_use(4, farm.target_cell))

	# Outer ring stays cursed.
	gs.holy_water = 5
	farm.healing.cleanse(Vector2i(1, 1))
	check("ring kept", g.get_cell_source_id(Vector2i(0, 0)) == CURSED and g.get_cell_source_id(Vector2i(0, 1)) == CURSED and g.get_cell_source_id(Vector2i(1, 0)) == CURSED)
	check("inner part healed", g.get_cell_source_id(Vector2i(1, 1)) == 0 and g.get_cell_source_id(Vector2i(2, 2)) == 0)
	farm.healing.cleanse(Vector2i(74, 24))
	check("east ring kept", g.get_cell_source_id(Vector2i(75, 24)) == CURSED and g.get_cell_source_id(Vector2i(74, 25)) == CURSED)
	var before: int = gs.holy_water
	check("ring-only patch not usable", farm.healing.cleansable_cells(Vector2i(-1, 13)).is_empty())
	farm.healing.cleanse(Vector2i(-1, 13))
	check("ring-only patch costs nothing", gs.holy_water == before)

	# None left.
	gs.holy_water = 0
	check("not usable with none", not farm.can_use(4, Vector2i(38, 13)))
	farm.healing.cleanse(Vector2i(38, 3))
	check("no heal with none", g.get_cell_source_id(Vector2i(38, 3)) == CURSED)

	# Saved count.
	gs.holy_water = 3
	gs.save_game()
	gs.holy_water = 0
	gs.load_game()
	check("holy water saved", gs.holy_water == 3)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
