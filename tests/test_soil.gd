extends SceneTree
## Soil can turn back into grass: the Hoe on empty soil, or 3 nights with no crop.
## Fields get ragged grass edges instead of hard squares.
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
	var player: Node = main.get_node("World/Player")
	var hud: Node = main.get_node("HUD")
	var edges: Node2D = main.get_node("Farm/SoilEdges")
	var wet_edges: Node2D = main.get_node("Farm/WetEdges")
	var soil_index: int = main.get_node("Farm/Soil").get_index()
	check("order: soil, wet edges, grass edges, curse edges", wet_edges.get_index() == soil_index + 1 and edges.get_index() == soil_index + 2 and edges.get_index() < main.get_node("Farm/CurseEdges").get_index())
	check("grass atlas size", edges.ATLAS.get_size() == Vector2(512, 256))
	check("no soil, no edges", edges._pieces.is_empty())

	# The Hoe tills, then the Hoe again turns empty soil back into grass.
	player.global_position = farm.ground.to_global(farm.ground.map_to_local(Vector2i(18, 12)))
	for i in 5:
		await physics_frame
	var cell: Vector2i = farm.target_cell
	await press("tool_1")
	await press("use_tool")
	check("tilled", farm.is_tilled(cell))
	check("a lone soil tile gets 4 grass sides", edges._pieces.size() == 4)
	await physics_frame
	check("fresh soil says nothing", hud.crop_status_label.text == "")
	farm.soil_idle[cell] = 2
	await physics_frame
	await physics_frame
	check("warns on its last night", hud.crop_status_label.text == "Empty soil: grass returns tonight.")
	farm.soil_idle.erase(cell)
	await press("use_tool")
	check("hoe turns it back to grass", not farm.is_tilled(cell) and farm.is_farmable(cell))
	check("edges gone with it", edges._pieces.is_empty())

	# Soil with a crop can't be hoed away.
	await press("use_tool")
	await press("tool_3")
	await press("use_tool")
	await press("tool_1")
	check("planted", farm.crops.has(cell))
	check("hoe not usable on a crop", not farm.can_use(0, cell))  # 0 is Player.Tool.HOE
	await press("use_tool")
	check("crop and soil stay", farm.crops.has(cell) and farm.is_tilled(cell))

	# Two touching tiles share a side, so that side has no edge.
	var a := Vector2i(10, 14)
	var b := Vector2i(11, 14)
	farm.till(a)
	farm.till(b)
	farm._refresh_soil_edges()
	var at := func(c: Vector2i) -> int:
		return edges._pieces.filter(func(p: Dictionary) -> bool: return farm.soil.local_to_map(p["to"].get_center()) == c).size()
	check("touching tiles: 3 sides each", at.call(a) == 3 and at.call(b) == 3)

	# Watered soil gets a thin ragged edge over the dry soil beside it, not over grass.
	var wet_at := func(c: Vector2i) -> int:
		return wet_edges._pieces.filter(func(p: Dictionary) -> bool: return farm.soil.local_to_map(p["to"].get_center()) == c).size()
	check("no wet soil, no wet edges", wet_edges._pieces.is_empty())
	farm.water(a)
	farm._refresh_soil_edges()
	check("the dry neighbor gets one wet edge", wet_at.call(b) == 1 and wet_at.call(a) == 0)
	check("wet edge atlas", wet_edges.ATLAS.get_size() == Vector2(512, 256))

	# Empty soil goes back to grass after 3 nights; soil with a crop stays.
	check("balance number", gs.BALANCE.soil_idle_nights == 3)
	gs.end_day()
	check("soil dries overnight, and its wet edges go", not farm.is_watered(a) and wet_edges._pieces.is_empty())
	gs.end_day()
	check("still soil after 2 nights", farm.is_tilled(a) and farm.soil_idle.get(a, 0) == 2)
	check("planted cell isn't counted", not farm.soil_idle.has(cell))
	# Watering doesn't keep it: only a crop does.
	farm.water(b)
	gs.end_day()
	check("grass after 3 nights", not farm.is_tilled(a) and not farm.is_tilled(b))
	check("cell forgotten", not farm.soil_idle.has(a))
	check("planted soil stays", farm.is_tilled(cell) and farm.crops.has(cell))
	check("edges follow", at.call(a) == 0 and at.call(cell) == 4)
	check("saved", not gs.farm_state["tilled"].has(a) and gs.farm_state.has("soil_idle"))
	# Old saves have no soil_idle: test_old_save checks they still load.

	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
