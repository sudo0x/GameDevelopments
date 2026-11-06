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
	var only_find := func(c: Vector2i) -> bool: return c == find
	farm.healing.mark_tonight(only_find)
	farm.healing.curse_returns(only_find)
	farm.healing.mark_tonight(farm._can_curse_take)
	gs.end_day()
	# For the next run to compare: a restart must mark the same tiles.
	var file := FileAccess.open("user://marked.txt", FileAccess.WRITE)
	file.store_var(farm.healing.marked)
	file.close()
	print("saved: cleansed=%d money=%d" % [farm.healing.cleansed.size(), gs.money])
	quit()
