extends SceneTree
## Placing crafted buildings with the Build tool, by real key presses.
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


func aim_at(player: Node, g: TileMapLayer, cell: Vector2i) -> void:
	player.global_position = g.to_global(g.map_to_local(cell + Vector2i(-1, 0))) + Vector2(0, 8)
	player.facing = 3
	for i in 5:
		await physics_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var hud: Node = main.get_node("HUD")
	var player: Node = main.get_node("World/Player")
	var lantern = gs.BUILDINGS[0]
	var cell := Vector2i(16, 12)

	await press("tool_6")
	await aim_at(player, g, cell)
	await press("use_tool")
	check("nothing placed with none crafted", farm.builder.placed.is_empty())

	gs.buildings[&"lantern_post"] = 2
	await press("use_tool")
	check("placed", farm.builder.placed.has(cell))
	check("one used", gs.building_count(lantern) == 1)
	check("label updates", hud.tool_label.text.contains("Lantern post: 1"))
	var node: Node2D = farm.builder.placed[cell]["node"]
	check("in the y-sorted World", node.get_parent().name == "World")
	check("stands where the preview was", node.global_position == g.to_global(g.map_to_local(cell) + farm.BUILDING_BASE))
	check("has its light", node.get_node("Light").enabled)
	await physics_frame
	await physics_frame
	check("the tile is taken", not farm.can_build(cell))
	check("preview goes red", farm.build_preview.modulate == farm.build_preview.INVALID_COLOR)
	await press("use_tool")
	check("can't stack a second", gs.building_count(lantern) == 1 and farm.builder.placed.size() == 1)
	check("can't till under it", not farm.can_use(0, cell))

	# It's solid.
	player.global_position = node.global_position + Vector2(0, 24)
	for i in 3:
		await physics_frame
	Input.action_press("move_up")
	for i in 50:
		await physics_frame
	Input.action_release("move_up")
	check("blocks walking", player.global_position.y > node.global_position.y)

	# Refused spots spend nothing.
	await aim_at(player, g, Vector2i(35, 12))
	check("aiming at the curse", farm.target_cell == Vector2i(35, 12))
	await press("use_tool")
	check("no building on the curse", gs.building_count(lantern) == 1 and farm.builder.placed.size() == 1)

	# Healed land is clean land.
	gs.holy_water = 1
	farm.healing.cleanse(Vector2i(35, 12))
	await physics_frame
	await physics_frame
	await press("use_tool")
	check("builds on healed land", farm.builder.placed.has(Vector2i(35, 12)))
	check("last one used", gs.building_count(lantern) == 0)
	await aim_at(player, g, Vector2i(20, 15))
	await press("use_tool")
	check("none left", farm.builder.placed.size() == 2)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
