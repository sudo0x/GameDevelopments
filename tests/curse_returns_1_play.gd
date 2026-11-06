extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.holy_water = 4
	gs.day = 4
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var find := Vector2i(53, 11)
	farm.healing.cleanse(Vector2i(54, 12))
	# The find's own tile goes first, so the next run has to remember it was dug up.
	gs.day = 5
	farm.healing.curse_returns(func(c: Vector2i) -> bool: return c == find)
	gs.end_day()
	print("saved: cleansed=%d money=%d" % [farm.healing.cleansed.size(), gs.money])
	quit()
