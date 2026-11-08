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
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	inv.holy_water = 2
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 5:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var player: Node = main.get_node("World/Player")
	var HOE := 0
	check("old farm cell still works", farm.can_use(HOE, Vector2i(18, 12)))
	check("shore outside the old farm area works", farm.can_use(HOE, Vector2i(9, 13)))
	check("south shore works", farm.can_use(HOE, Vector2i(20, 21)))
	check("cursed can't be tilled", not farm.can_use(HOE, Vector2i(38, 13)))
	check("off the map can't be tilled", not farm.can_use(HOE, Vector2i(200, 13)))
	check("clearing is grass and farmable", farm.can_use(HOE, Vector2i(58, 18)))

	# No tilling under anything solid.
	for path: Variant in ["ShippingBox", "ShopStall", "House", "LanternDoor", "LanternStall", "LanternSouthWest", "LanternSouthEast"]:
		var obj: Node2D = main.get_node("World/" + path)
		var cell: Vector2i = g.local_to_map(g.to_local(obj.global_position + Vector2(0, -5)))
		check(path + " cell blocked " + str(cell), not farm.can_use(HOE, cell))
	var stall: Node2D = main.get_node("World/ShopStall")
	var below: Vector2i = g.local_to_map(g.to_local(stall.global_position + Vector2(0, 16)))
	check("cell in front of the stall is free", farm.can_use(HOE, below))

	# Standing on a cell doesn't block it (player excluded).
	var stand := Vector2i(16, 16)
	player.global_position = g.to_global(g.map_to_local(stand))
	for i in 4:
		await physics_frame
	check("player's own cell not blocked", farm.can_use(HOE, stand))

	# The whole loop on healed land, by input.
	var c := Vector2i(38, 13)
	farm.healing.cleanse(c)
	await physics_frame
	check("healed land can be tilled", farm.can_use(HOE, c))
	player.global_position = g.to_global(g.map_to_local(c + Vector2i(-1, 0)))
	player.facing = 3
	for i in 5:
		await physics_frame
	check("target on healed land", farm.target_cell == c)
	await press("tool_1")
	await press("use_tool")
	check("tilled healed land", farm.is_tilled(c))
	await press("tool_3")
	await press("use_tool")
	check("planted on healed land", farm.crops.has(c))
	var crop: Node = farm.crops[c]
	for d in 3:
		farm.water(c)
		progress.end_day()
	check("grows on healed land", crop.is_ripe())
	await press("tool_4")
	await press("use_tool")
	check("harvested on healed land", inv.harvest_count(inv.CROPS[0]) == 1)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
