extends SceneTree
## Crops show a small icon only when they need the player: a water drop, or a ripe sparkle.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func press(action: String) -> void:
	for pressed in [true, false]:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await physics_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var progress: Node = root.get_node("Progress")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var player: Node = main.get_node("World/Player")
	player.global_position = farm.ground.to_global(farm.ground.map_to_local(Vector2i(18, 12)))
	for i in 5:
		await physics_frame
	var cell: Vector2i = farm.target_cell
	await press("tool_1")
	await press("use_tool")
	await press("tool_3")
	await press("use_tool")
	var crop: Node = farm.crops[cell]
	check("a new crop asks for water", crop.need_icon == farm.WATER_ICON and crop._need_sprite.visible)
	await press("tool_2")
	await press("use_tool")
	check("watered: the icon goes", crop.need_icon == null and not crop._need_sprite.visible)
	progress.end_day()
	check("next morning it asks again", crop.need_icon == farm.WATER_ICON)
	crop.set_days_grown(crop.data.days_to_grow)
	farm._refresh_crop_needs()
	check("ripe shows the sparkle, not water", crop.need_icon == farm.RIPE_ICON)
	check("the icon sits above the plant", crop._need_sprite.position.y == crop.NEED_HEIGHTS[3])
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
