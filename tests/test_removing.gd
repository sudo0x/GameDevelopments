extends SceneTree
## The hand tool picks placed buildings back up, and leaves the house and shop stall alone.
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
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var saves: Node = root.get_node("SaveGame")
	inv.buildings[&"lantern_post"] = 1
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var hud: Node = main.get_node("HUD")
	var player: Node = main.get_node("World/Player")
	var lantern = inv.BUILDINGS[0]
	var cell := Vector2i(16, 12)
	player.global_position = g.to_global(g.map_to_local(cell + Vector2i(-1, 0))) + Vector2(0, 8)
	player.facing = 3
	for i in 5:
		await physics_frame

	await press("tool_6")
	await press("use_tool")
	check("placed", farm.builder.placed.has(cell) and inv.building_count(lantern) == 0)
	var node: Node2D = farm.builder.placed[cell]["node"]
	await physics_frame
	await physics_frame
	check("status explains it", hud.crop_status_label.text == "Lantern post: press 4, then Space to pick up.")
	await press("tool_4")
	check("hand can use it", farm.can_use(3, cell))
	await press("use_tool")
	await process_frame
	check("gone from the map", not farm.builder.placed.has(cell) and not is_instance_valid(node))
	check("back in the bag", inv.building_count(lantern) == 1)
	check("notice", hud.notice_label.text == "Picked up: Lantern post")
	await physics_frame
	await physics_frame
	await physics_frame
	check("status clears", hud.crop_status_label.text == "")
	check("tile is free again", farm.can_build(cell))
	check("farmable again", farm.can_use(0, cell))
	await press("use_tool")
	check("hand on empty ground does nothing", inv.building_count(lantern) == 1)

	await press("tool_6")
	await press("use_tool")
	check("can place it again", farm.builder.placed.has(cell) and inv.building_count(lantern) == 0)

	# The map's lanterns can move now (test_moving.gd); the house and shop stall can't.
	for path in ["House", "ShopStall"]:
		var own: Node2D = main.get_node("World/" + path)
		var own_cell: Vector2i = g.local_to_map(g.to_local(own.global_position) - Vector2(0, 12))
		check(path + " stays", not farm.can_use(3, own_cell))

	# Picking up is saved.
	farm.builder.pick_up(cell)
	await process_frame
	progress.end_day()
	check("save has no building", saves.farm_state["buildings"].is_empty())
	inv.buildings.clear()
	saves.load_game()
	check("the bag count is saved", inv.building_count(lantern) == 1)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
