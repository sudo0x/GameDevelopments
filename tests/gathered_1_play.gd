extends SceneTree
## Gathers a tree and a rock, reveals a hidden tree, then sleeps. Checked by gathered_2_check.gd.


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.holy_water = 1
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	for i in 3:
		farm.gathering.hit(Vector2i(22, 6))
		farm.gathering.hit(Vector2i(18, 7))
	farm.healing.cleanse(Vector2i(44, 12))
	for i in 3:
		farm.gathering.hit(Vector2i(44, 12))
	farm.gathering.hit(Vector2i(14, 7))
	gs.end_day()
	quit()
