extends SceneTree
## Setting the nightly number to 0 turns the returning curse off.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func _initialize() -> void:
	_run()


func _run() -> void:
	# Before the scene loads: scripts read `GameState.BALANCE.x` once, when they compile.
	load("res://data/balance.tres").curse_return_per_night = 0
	var gs: Node = root.get_node("GameState")
	gs.holy_water = 2
	gs.day = 5
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var healing: Node = main.get_node("Farm").healing
	healing.cleanse(Vector2i(38, 13))
	gs.end_day()
	gs.end_day()
	check("nothing returned", healing.cleansed.size() == 9)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
