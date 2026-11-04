extends SceneTree
var fails := 0
func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1
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
	var c := Vector2i(38, 13)
	check("holy water count from the morning", gs.holy_water == 3)
	check("healed land came back", g.get_cell_source_id(c) == 0 and g.get_cell_source_id(c + Vector2i.ONE) == 0)
	check("texture piece lines up", g.get_cell_atlas_coords(c) == Vector2i(posmod(c.x, 4), posmod(c.y, 4)))
	check("9 cells remembered", farm.cleansed.size() == 9)
	check("next door still cursed", g.get_cell_source_id(c + Vector2i(2, 0)) == 1)
	check("after-save heal reverted", g.get_cell_source_id(Vector2i(38, 3)) == 1)
	check("crop on healed land back", farm.crops.has(c) and farm.crops[c].days_grown == 1)
	check("soil back", farm.is_tilled(c))
	var fx := farm.get_children().filter(func(n: Node) -> bool: return n.scene_file_path.ends_with("cleanse_effect.tscn"))
	check("no effect on load", fx.is_empty())
	check("can't re-heal it", farm.cleansable_cells(c).is_empty())
	player.global_position = g.to_global(g.map_to_local(Vector2i(37, 12)))
	for i in 3:
		await physics_frame
	var x0: float = player.global_position.x
	Input.action_press("move_right")
	for i in 30:
		await physics_frame
	Input.action_release("move_right")
	check("walkable after reload", player.global_position.x > x0 + 25)
	farm.cleanse(c + Vector2i(3, 0))
	gs.end_day()
	check("18 cells, no duplicates", farm.cleansed.size() == 18 and gs.farm_state["cleansed"].size() == 18)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
