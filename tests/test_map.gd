extends SceneTree
var fails := 0
func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1
func _initialize() -> void:
	_run()
func _run() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var player: Node = main.get_node("World/Player")
	var used := g.get_used_rect()
	check("map size", used == Rect2i(0, 0, 76, 26))
	var cam: Camera2D = player.get_node("Camera2D")
	check("camera reaches new east edge", cam.limit_right == 76 * 32)
	for y in range(6, 21):
		var s := "%2d " % y
		for x in range(30, 76):
			s += "#" if g.get_cell_source_id(Vector2i(x, y)) == 1 else "."
		print(s)
	# Border stays cursed, or a player could leave the map once land heals nearby.
	var border_ok := true
	for x in 76:
		for y in [0, 25]:
			border_ok = border_ok and g.get_cell_source_id(Vector2i(x, y)) == 1
	for y in 26:
		for x in [0, 75]:
			border_ok = border_ok and g.get_cell_source_id(Vector2i(x, y)) == 1
	check("whole map border is cursed", border_ok)
	# Flood fill from the player: nothing east of the shore is reachable yet.
	var start: Vector2i = g.local_to_map(g.to_local(player.global_position))
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if used.has_point(n) and not seen.has(n) and g.get_cell_source_id(n) != 1:
				seen[n] = true
				todo.append(n)
	var east := 0
	for c: Vector2i in seen:
		east = maxi(east, c.x)
	check("clearings not reachable yet (east-most %d)" % east, east < 40)
	check("3 clearings exist", g.get_cell_source_id(Vector2i(50, 7)) == 0 and g.get_cell_source_id(Vector2i(58, 18)) == 0 and g.get_cell_source_id(Vector2i(69, 12)) == 0)
	# Player really can't walk east off the shore.
	player.global_position = g.to_global(g.map_to_local(Vector2i(33, 13)))
	Input.action_press("move_right")
	for i in 240:
		await physics_frame
	Input.action_release("move_right")
	var cell: Vector2i = g.local_to_map(g.to_local(player.global_position))
	check("blocked at the shore edge (stopped at x=%d)" % cell.x, cell.x < 40)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
