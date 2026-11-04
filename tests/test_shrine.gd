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
func stand(player: Node, pos: Vector2) -> void:
	player.global_position = pos
	for i in 6:
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
	var player: Node = main.get_node("World/Player")
	var hud: Node = main.get_node("HUD")
	var shrine: Node2D = main.get_node("World/Shrine")
	var cell: Vector2i = g.local_to_map(g.to_local(shrine.global_position))
	print("shrine cell ", cell)
	check("stands on the clearing's grass", g.get_cell_source_id(cell) == 0)
	check("starts cursed", not shrine.restored and shrine.sprite.texture == shrine.cursed_texture and not shrine.light.enabled)
	check("can't till under it", not farm.can_use(0, cell))

	gs.holy_water = 2
	await stand(player, shrine.global_position + Vector2(0, 18))
	await press("interact")
	check("refused with too little", not shrine.restored and gs.holy_water == 2)
	check("says what it needs", hud.notice_label.text == "The shrine needs 3 holy water.")

	gs.holy_water = 4
	var money0: int = gs.money
	await press("interact")
	check("restored", shrine.restored)
	check("costs 3, then the find at (63, 8) gives 2 back", gs.holy_water == 4 - 3 + 2)
	print("holy after: ", gs.holy_water, " money +", gs.money - money0)
	check("new look and light", shrine.sprite.texture == shrine.restored_texture and shrine.light.enabled)
	# The finds' notices come first; the shrine's waits its turn after them.
	var restored_notice := func(text: String) -> bool: return text.begins_with("The old shrine is restored")
	check("shrine notice shown or waiting", restored_notice.call(hud.latest_notice()) or hud._waiting_notices.any(restored_notice))
	var healed: int = farm.healing.cleansed.size()
	print("healed cells ", healed, " percent ", gs.healed_percent)
	check("large area healed", healed > 100)
	check("circle: 9 away healed", g.get_cell_source_id(cell + Vector2i(-9, 0)) == 0)
	check("circle: 10 away still cursed", g.get_cell_source_id(cell + Vector2i(-10, 0)) == 1)
	check("corner of the square still cursed", g.get_cell_source_id(cell + Vector2i(-8, -8)) == 1)
	check("east ring kept", g.get_cell_source_id(Vector2i(75, cell.y)) == 1)
	check("top ring kept", g.get_cell_source_id(Vector2i(cell.x, 0)) == 1 or cell.y > 9)
	check("finds in range paid", gs.money == money0 + 120)
	check("glimmers removed", not farm.healing._glimmers.has(Vector2i(63, 8)) and not farm.healing._glimmers.has(Vector2i(64, 18)))

	var h: int = gs.holy_water
	await press("interact")
	check("second time costs nothing", gs.holy_water == h)
	check("at peace", hud.latest_notice() == "The shrine is at peace." or hud._waiting_notices.has("The shrine is at peace."))

	var fx := func() -> int: return farm.healing.get_children().filter(func(n: Node) -> bool: return n.scene_file_path.ends_with("cleanse_effect.tscn")).size()
	check("effect running", fx.call() == 1)
	for i in 200:
		await process_frame
	check("effect finished", fx.call() == 0)

	gs.end_day()
	main.free()
	var again: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(again)
	await process_frame
	var s2: Node2D = again.get_node("World/Shrine")
	check("still restored after reload", s2.restored and s2.sprite.texture == s2.restored_texture and s2.light.enabled)
	check("land still healed", again.get_node("Farm").healing.cleansed.size() == healed)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
