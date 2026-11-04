extends SceneTree
## Places a lantern, keeps one unplaced, then sleeps. Checked by buildings_2_check.gd.


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.buildings[&"lantern_post"] = 2
	gs.holy_water = 1
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	farm.builder.place(Vector2i(16, 12), gs.BUILDINGS[0])
	farm.healing.cleanse(Vector2i(38, 13))
	gs.end_day()
	quit()
