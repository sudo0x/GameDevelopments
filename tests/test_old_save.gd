extends SceneTree
## tests/fixtures/save_v1.cfg was made by an older version of the game. It must keep loading,
## or players would lose their farms. Never regenerate it to make this test pass.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var old_save := FileAccess.get_file_as_string("res://tests/fixtures/save_v1.cfg")
	check("fixture found", not old_save.is_empty())
	var out := FileAccess.open("user://save.cfg", FileAccess.WRITE)
	out.store_string(old_save)
	out.close()
	gs.load_game()
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	check("day", gs.day == 2)
	check("money", gs.money == 235)
	check("holy water", gs.holy_water == 6)
	check("harvest", gs.harvest_count(gs.CROPS[0]) == 4)
	check("seeds", gs.seed_count(gs.CROPS[0]) == 9 and gs.seed_count(gs.CROPS[1]) == 4)
	check("healed land", farm.healing.cleansed.size() == 175 and g.get_cell_source_id(Vector2i(38, 10)) == 0)
	check("shrine restored", farm.healing.shrine.restored)
	check("crops", farm.crops.size() == 2 and farm.crops[Vector2i(38, 11)].data.id == &"carrot")
	check("crop growth", farm.crops[Vector2i(38, 11)].days_grown == 1)
	check("soil", farm.is_tilled(Vector2i(20, 12)))
	check("dug-up find stays gone", not farm.healing._glimmers.has(Vector2i(38, 10)))
	check("other finds still buried", farm.healing._glimmers.has(Vector2i(42, 15)))
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
