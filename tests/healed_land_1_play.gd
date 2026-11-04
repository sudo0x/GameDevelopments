extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.holy_water = 4
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	farm.healing.cleanse(Vector2i(38, 13))
	await physics_frame
	farm.till(Vector2i(38, 13))
	farm.plant(Vector2i(38, 13), gs.CROPS[1])
	farm.water(Vector2i(38, 13))
	gs.end_day()
	farm.healing.cleanse(Vector2i(38, 3))   # after the last save: must revert
	print("A saved: cleansed=%d holy=%d" % [farm.healing.cleansed.size(), gs.holy_water])
	quit()
