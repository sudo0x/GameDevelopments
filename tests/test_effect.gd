extends SceneTree
var fails := 0
func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1
func effects(farm: Node) -> Array:
	return farm.healing.get_children().filter(func(n: Node) -> bool: return n.scene_file_path.ends_with("cleanse_effect.tscn"))
func _initialize() -> void:
	_run()
func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	inv.holy_water = 5
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var c := Vector2i(40, 13)
	farm.healing.cleanse(c)
	check("land healed at once", g.get_cell_source_id(c) == 0 and g.get_cell_source_id(c + Vector2i.ONE) == 0)
	check("no double spend possible on same patch", farm.healing.cleansable_cells(c).is_empty())
	var list := effects(farm)
	check("one effect running", list.size() == 1)
	var e: Node2D = list[0]
	var pieces := e.get_children().filter(func(n: Node) -> bool: return n is Sprite2D)
	check("9 fading tiles", pieces.size() == 9)
	check("center piece over center cell", e.position == g.map_to_local(c))
	var corner: Sprite2D = pieces[0]
	check("region is a 32 tile", corner.region_rect.size == Vector2(32, 32))
	check("sparkles on", e.get_node("Sparkles").emitting)
	var center_piece: Sprite2D = pieces[4]
	var saw_order := false
	var peak := 0.0
	for i in 40:
		await process_frame
		peak = maxf(peak, e.get_node("Light").energy)
		if center_piece.modulate.a < 0.7 and corner.modulate.a > 0.9:
			saw_order = true
	check("center fades before corners", saw_order)
	check("light flashes", peak > 1.0)
	for i in 120:
		await process_frame
	check("effect removed itself", effects(farm).is_empty())
	# Two at once, and pausing in the middle (the shop) must not break it.
	farm.healing.cleanse(Vector2i(44, 13))
	farm.healing.cleanse(Vector2i(48, 13))
	check("two effects", effects(farm).size() == 2)
	paused = true
	for i in 20:
		await process_frame
	check("paused effects wait", effects(farm).size() == 2)
	paused = false
	for i in 150:
		await process_frame
	check("both removed", effects(farm).is_empty())
	# Sleeping straight after.
	farm.healing.cleanse(Vector2i(52, 13))
	progress.end_day()
	for i in 150:
		await process_frame
	check("removed across a day change", effects(farm).is_empty())
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
