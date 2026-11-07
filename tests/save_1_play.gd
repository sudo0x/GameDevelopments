extends SceneTree
## Run 1: play a day, ending with things that must survive a restart.
func _initialize() -> void:
	_run()
func _run() -> void:
	print("user dir: ", OS.get_user_data_dir())
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	check_new(inv, progress)
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var c := inv.CROPS as Array
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
		progress.end_day()
	inv.harvest[&"carrot"] = 4
	inv.ship_all()
	inv.harvest[&"radish"] = 2
	farm.water(Vector2i(20, 12))         # watered today, should be dry after sleeping
	progress.end_day()
	inv.harvest[&"pumpkin"] = 9           # after the last save: must be lost
	inv.money += 1000
	print("saved day ", progress.day, " money ", inv.money - 1000)
	quit()

func check_new(inv: Node, progress: Node) -> void:
	print("fresh start day=%d money=%d" % [progress.day, inv.money])
