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
	var inv: Node = root.get_node("Inventory")
	var saves: Node = root.get_node("SaveGame")
	inv.money = 111
	saves.save_game()
	check("save exists", FileAccess.file_exists(saves.SAVE_PATH))
	check("no temporary file left", not FileAccess.file_exists(saves.SAVE_TEMP_PATH))

	# A crash mid-save leaves a broken temporary file. The real save must be unharmed.
	var broken := FileAccess.open(saves.SAVE_TEMP_PATH, FileAccess.WRITE)
	broken.store_string("half a save")
	broken.close()
	inv.money = 0
	saves.load_game()
	check("real save still loads", inv.money == 111)

	# The next save replaces both.
	inv.money = 222
	saves.save_game()
	inv.money = 0
	saves.load_game()
	check("next save works", inv.money == 222)
	check("broken temporary file gone", not FileAccess.file_exists(saves.SAVE_TEMP_PATH))
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
