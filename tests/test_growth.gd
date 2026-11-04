extends SceneTree
## Crops must look alive from the first watered night, and tell the player what they need.
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
	var hud: Node = main.get_node("HUD")
	var player: Node = main.get_node("World/Player")

	# Every crop's stages, night by night.
	var expected := {
		&"radish": [0, 1, 2, 3],
		&"carrot": [0, 1, 1, 2, 2, 3],
		&"pumpkin": [0, 1, 1, 1, 1, 2, 2, 2, 3],
	}
	var cell := Vector2i(16, 12)
	for x in 3:
		var data = gs.CROPS[x]
		var c := cell + Vector2i(x, 0)
		farm.till(c)
		farm.plant(c, data)
		var crop: Node = farm.crops[c]
		var seen: Array = [crop.stage]
		for day in data.days_to_grow:
			crop.grow_one_day()
			seen.append(crop.stage)
		print(data.id, " ", seen)
		check("%s stages" % data.id, seen == expected[data.id])
		check("%s ripe only at the end" % data.id, crop.is_ripe() and crop.days_grown == data.days_to_grow)

	# The status follows what the player faces.
	for i in 5:
		await physics_frame
	check("nothing shown on empty ground", hud.crop_status_label.text == "")
	var target: Vector2i = farm.target_cell
	await press("tool_1")
	await press("use_tool")
	await press("tool_3")
	gs.seeds[&"pumpkin"] = 1
	player.seed_index = 2
	await press("use_tool")
	await physics_frame
	check("needs water", hud.crop_status_label.text == "Pumpkin: 0 of 8 days, needs water.")
	await press("tool_2")
	await press("use_tool")
	await physics_frame
	check("watered", hud.crop_status_label.text == "Pumpkin: 0 of 8 days, watered. Sleep to grow.")
	gs.end_day()
	await physics_frame
	await physics_frame
	check("next morning needs water again", hud.crop_status_label.text == "Pumpkin: 1 of 8 days, needs water.")
	check("sprouted after one night", farm.crops[target].stage == 1)
	for day in 7:
		farm.crops[target].grow_one_day()
	await physics_frame
	await physics_frame
	check("ripe message", hud.crop_status_label.text == "Pumpkin is ripe! Press 4 to harvest.")
	await press("tool_4")
	await press("use_tool")
	await physics_frame
	await physics_frame
	check("empty soil after harvest", hud.crop_status_label.text == "Empty soil: grass returns in 3 nights.")

	# Lanterns flicker around their base energy, and not all together.
	var a: PointLight2D = main.get_node("World/LanternDoor/Light")
	var b: PointLight2D = main.get_node("World/LanternStall/Light")
	# Start times are random, and the flicker repeats every ~10.5 s, so about 1 run in 500
	# two lanterns landed a whole repeat apart and flickered alike. Set them apart instead.
	b._time = a._time + 1.0
	var low := 99.0
	var high := -99.0
	var differ := false
	for i in 120:
		await process_frame
		low = minf(low, a.energy)
		high = maxf(high, a.energy)
		differ = differ or absf(a.energy - b.energy) > 0.01
	print("lantern energy %.2f to %.2f" % [low, high])
	check("flickers", high - low > 0.05)
	check("stays gentle", low > 0.8 and high < 1.2)
	check("lanterns differ", differ)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
