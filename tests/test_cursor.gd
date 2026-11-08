extends SceneTree
## The tile cursor: art corners around the target, white where the tool works, red where it
## doesn't, bigger for holy water, and a gentle pulse.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func press(action: String) -> void:
	for pressed: Variant in [true, false]:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await physics_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var player: Node = main.get_node("World/Player")
	var cursor: Node2D = farm.highlight
	check("uses the cursor art, 54 pixels with 12-pixel corners", cursor.CURSOR.get_size() == Vector2(54, 54) and cursor._style.get_texture_margin(SIDE_LEFT) == 12.0)

	# On clean grass the hoe works: white, framing the tile from just outside.
	player.global_position = farm.ground.to_global(farm.ground.map_to_local(Vector2i(18, 12)))
	for i in 4:
		await physics_frame
	await press("tool_1")
	await physics_frame
	var tile := Vector2(farm.ground.tile_set.tile_size)
	check("white where the tool works", cursor._valid and cursor._style.modulate_color == cursor.VALID_COLOR)
	check("one tile, plus the frame around it", cursor._cell_rect.size == tile)

	# The watering can on dry grass does nothing: red.
	await press("tool_2")
	await physics_frame
	check("red where it doesn't", not cursor._valid)
	await process_frame
	check("drawn in the red tint", cursor._style.modulate_color == cursor.INVALID_COLOR)

	# Holy water covers a 3x3 patch, and the same art stretches to fit it.
	inv.holy_water = 1
	await press("tool_5")
	await physics_frame
	check("holy water: a 3x3 patch", cursor._cell_rect.size == tile * 3)

	# A slow pulse, never fully gone.
	var low := 1.0
	var high := 0.0
	for i in 90:
		await process_frame
		low = minf(low, cursor.modulate.a)
		high = maxf(high, cursor.modulate.a)
	check("pulses, but stays visible", high - low > 0.2 and low >= cursor.PULSE_LOW - 0.01)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
