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
	var player: Node = main.get_node("World/Player")
	var hud: Node = main.get_node("HUD")
	player.global_position = farm.ground.to_global(farm.ground.map_to_local(Vector2i(18, 12)))
	for i in 5:
		await physics_frame
	var cell: Vector2i = farm.target_cell
	check("target is farmable " + str(cell), farm.is_farmable(cell))

	await press("tool_1")
	await press("use_tool")
	check("tilled", farm.is_tilled(cell))
	await press("tool_3")
	await press("use_tool")
	check("planted", farm.crops.has(cell))
	var radish = gs.CROPS[0]
	check("seed used", gs.seed_count(radish) == 9)

	await press("tool_4")
	check("hand refuses empty-ripe check on unripe", not farm.can_use(3, cell))
	await press("use_tool")
	check("unripe crop stays", farm.crops.has(cell) and gs.harvest_count(radish) == 0)

	var neighbour := cell + Vector2i(5, 0)
	check("hand refuses empty cell", not farm.can_use(3, neighbour))

	gs.end_day()
	check("unwatered does not grow", farm.crops[cell].days_grown == 0)
	for d in 3:
		await press("tool_2")
		await press("use_tool")
		check("watered day %d" % d, farm.is_watered(cell))
		gs.end_day()
	var crop: Node = farm.crops[cell]
	check("ripe after 3 watered days", crop.is_ripe())

	await press("tool_4")
	check("hand usable on ripe", farm.can_use(3, cell))
	await press("use_tool")
	await process_frame
	check("harvest counted", gs.harvest_count(radish) == 1)
	check("crop removed from grid", not farm.crops.has(cell))
	check("crop node freed", not is_instance_valid(crop))
	check("soil stays tilled", farm.is_tilled(cell))
	await press("use_tool")
	check("second press harvests nothing", gs.harvest_count(radish) == 1)
	check("HUD status text", hud.status_label.text.contains("Island healed"))
	check("HUD money text", hud.money_label.text == "0")
	print("inventory label:\n" + hud.status_label.text)

	await press("tool_3")
	await press("use_tool")
	check("can replant", farm.crops.has(cell) and gs.seed_count(radish) == 8)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
