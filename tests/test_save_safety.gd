extends SceneTree
## Saving goes through a temporary file, so a crash can't damage the real save.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.money = 111
	gs.save_game()
	check("save exists", FileAccess.file_exists(gs.SAVE_PATH))
	check("no temporary file left", not FileAccess.file_exists(gs.SAVE_TEMP_PATH))

	# A crash mid-save leaves a broken temporary file. The real save must be unharmed.
	var broken := FileAccess.open(gs.SAVE_TEMP_PATH, FileAccess.WRITE)
	broken.store_string("half a save")
	broken.close()
	gs.money = 0
	gs.load_game()
	check("real save still loads", gs.money == 111)

	# The next save replaces both.
	gs.money = 222
	gs.save_game()
	gs.money = 0
	gs.load_game()
	check("next save works", gs.money == 222)
	check("broken temporary file gone", not FileAccess.file_exists(gs.SAVE_TEMP_PATH))
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
