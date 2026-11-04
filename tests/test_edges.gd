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
	gs.holy_water = 10
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var edges: Node2D = main.get_node("Farm/CurseEdges")
	check("draws under the player and over soil", edges.get_index() > main.get_node("Farm/Soil").get_index() and edges.get_index() < main.get_node("Farm/Highlight").get_index())
	var atlas: Texture2D = edges.ATLAS
	check("atlas size", atlas.get_size() == Vector2(512, 256))
	var img := atlas.get_image()
	img.decompress()
	for row in 8:
		var solid := 0
		for x in 512:
			for y in 32:
				if img.get_pixel(x, row * 32 + y).a > 0.5:
					solid += 1
		var share := float(solid) / (512 * 32)
		print("row %d curse share %.2f" % [row, share])
		check("row %d not empty or full" % row, share > 0.02 and share < 0.5)
	var pieces: Array = edges._pieces
	print("pieces ", pieces.size())
	check("edges exist", pieces.size() > 100)
	var on_clean := true
	var in_atlas := true
	var bounds := Rect2(Vector2.ZERO, atlas.get_size())
	for p: Dictionary in pieces:
		var cell := g.local_to_map(p["to"].get_center())
		on_clean = on_clean and g.get_cell_source_id(cell) == 0
		in_atlas = in_atlas and bounds.encloses(p["from"])
	check("pieces only over clean tiles", on_clean)
	check("pieces inside the atlas", in_atlas)
	# A cursed cell's clean neighbor always gets a piece facing it.
	var c := Vector2i(30, 13)
	check("deep in the shore has none", pieces.filter(func(p: Dictionary) -> bool: return g.local_to_map(p["to"].get_center()) == Vector2i(20, 13)).is_empty())
	# Healing updates them.
	var before: int = pieces.size()
	var edge_cell := Vector2i(38, 13)
	var at := func(cell: Vector2i) -> int: return edges._pieces.filter(func(p: Dictionary) -> bool: return g.local_to_map(p["to"].get_center()) == cell).size()
	check("no piece in curse before", at.call(edge_cell) == 0)
	farm.healing.cleanse(edge_cell)
	check("center of a patch has no edge", at.call(edge_cell) == 0)
	check("patch rim has edges", at.call(edge_cell + Vector2i(1, 0)) > 0)
	check("count changed", edges._pieces.size() != before)
	# Fully surrounded grass: a one-cell island gets all four sides.
	g.set_cell(Vector2i(45, 3), 0, Vector2i(1, 3))
	edges.refresh(g)
	check("single clean cell gets 4 sides", at.call(Vector2i(45, 3)) == 4)
	# A cursed diagonal only: one corner.
	var rows := func(cell: Vector2i) -> Array: return edges._pieces.filter(func(p: Dictionary) -> bool: return g.local_to_map(p["to"].get_center()) == cell).map(func(p: Dictionary) -> int: return int(p["from"].position.y / 32))
	for x in range(43, 52):
		for y in range(3, 11):
			g.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	g.set_cell(Vector2i(47, 6), 1, Vector2i(0, 0))
	edges.refresh(g)
	check("diagonal-only cell gets the SE corner", (rows.call(Vector2i(46, 5)) as Array) == [5])
	check("NW corner", (rows.call(Vector2i(48, 7)) as Array) == [7])
	check("NE corner", (rows.call(Vector2i(46, 7)) as Array) == [4])
	check("SW corner", (rows.call(Vector2i(48, 5)) as Array) == [6])
	check("side below", (rows.call(Vector2i(47, 7)) as Array) == [0])
	check("side left", (rows.call(Vector2i(46, 6)) as Array) == [1])
	check("side above", (rows.call(Vector2i(47, 5)) as Array) == [2])
	check("side right", (rows.call(Vector2i(48, 6)) as Array) == [3])
	var t0 := Time.get_ticks_usec()
	for i in 20:
		edges.refresh(g)
	print("refresh ms ", (Time.get_ticks_usec() - t0) / 20000.0)
	check("refresh is cheap", (Time.get_ticks_usec() - t0) / 20000.0 < 15.0)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
