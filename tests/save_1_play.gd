extends SceneTree
## Run 1: play a day, ending with things that must survive a restart.
func _initialize() -> void:
	_run()
func _run() -> void:
	print("user dir: ", OS.get_user_data_dir())
	var gs: Node = root.get_node("GameState")
	check_new(gs)
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var c := gs.CROPS as Array
	for x in 4:
		farm.till(Vector2i(14 + x, 10))
	farm.till(Vector2i(20, 12))          # tilled, nothing planted
	farm.plant(Vector2i(14, 10), c[0])   # radish -> ripe
	farm.plant(Vector2i(15, 10), c[1])   # carrot -> mid-growth
	farm.plant(Vector2i(16, 10), c[2])   # pumpkin -> mid-growth
	farm.plant(Vector2i(17, 10), c[0])   # radish -> never watered
	for d in 3:
		for x in 3:
			farm.water(Vector2i(14 + x, 10))
		gs.end_day()
	gs.harvest[&"carrot"] = 4
	gs.ship_all()
	gs.harvest[&"radish"] = 2
	farm.water(Vector2i(20, 12))         # watered today, should be dry after sleeping
	gs.end_day()
	gs.harvest[&"pumpkin"] = 9           # after the last save: must be lost
	gs.money += 1000
	print("saved day ", gs.day, " money ", gs.money - 1000)
	quit()

func check_new(gs: Node) -> void:
	print("fresh start day=%d money=%d" % [gs.day, gs.money])
