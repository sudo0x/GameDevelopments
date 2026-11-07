extends SceneTree
## The title screen: Continue, New Game, and never losing a farm by accident.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await process_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	Input.flush_buffered_events()
	await process_frame


func open_title() -> Node:
	if current_scene:
		current_scene.free()
	var title: Node = load("res://scenes/ui/title_screen.tscn").instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	return title


func wait_for_game() -> void:
	for i in 6:
		await process_frame
	# A New Game opens with the story, which pauses; this test is about what happens around it.
	paused = false


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var saves: Node = root.get_node("SaveGame")
	check("the game opens on this screen", ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/title_screen.tscn")

	# First time: no save.
	check("no save at first", not saves.has_save())
	var title: Node = await open_title()
	check("no Continue", not title.continue_button.visible)
	check("New Game has focus", title.new_game_button.has_focus())
	check("Quit on desktop", title.quit_button.visible)
	await press("ui_accept")
	await wait_for_game()
	check("no question with nothing to lose", current_scene.name == "Main")
	check("day 1", progress.day == 1)

	# A farm in progress.
	progress.day = 9
	inv.money = 500
	inv.harvest[&"radish"] = 3
	inv.materials[&"wood"] = 7
	inv.buildings[&"fence"] = 2
	inv.holy_water = 4
	inv.strong_holy_water = 1
	inv.has_sword = true
	inv.has_purifying_hoe = true
	inv.hoe_uses_left = 2
	progress.hearts = 1
	inv.seeds[&"radish"] = 0
	saves.farm_state = {"cleansed": [Vector2i(38, 13)], "tilled": [], "crops": [], "gathered": [], "buildings": []}
	saves.save_game()
	title = await open_title()
	check("save found", saves.has_save())
	check("Continue shows the day", title.continue_button.visible and title.continue_button.text == "Continue (Day 9)")
	check("Continue has focus", title.continue_button.has_focus())
	await press("ui_accept")
	await wait_for_game()
	check("Continue starts the game", current_scene.name == "Main")
	check("the farm is there", progress.day == 9 and current_scene.get_node("Farm").healing.cleansed.size() == 1)

	# New Game asks, and the safe answer comes first.
	title = await open_title()
	title.new_game_button.pressed.emit()
	await process_frame
	check("it asks", title.confirm.visible)
	check("the warning names the farm", title.confirm_label.text.contains("Day 9"))
	check("No has focus", title.confirm_no.has_focus())
	await press("ui_accept")
	check("Enter by accident keeps the farm", not title.confirm.visible and saves.has_save() and current_scene == title)
	check("back on New Game", title.new_game_button.has_focus())
	title.new_game_button.pressed.emit()
	await process_frame
	await press("ui_cancel")
	check("Esc keeps the farm", not title.confirm.visible and saves.has_save() and progress.day == 9)

	# Really starting over.
	title.new_game_button.pressed.emit()
	await process_frame
	title.confirm_yes.pressed.emit()
	await wait_for_game()
	check("in the game", current_scene.name == "Main")
	check("save erased", not saves.has_save() and not FileAccess.file_exists(saves.SAVE_PATH))
	check("day and money", progress.day == 1 and inv.money == 0)
	check("seeds back", inv.seeds == inv.START_SEEDS)
	check("crops, materials, buildings", inv.harvest.is_empty() and inv.materials.is_empty() and inv.buildings.is_empty())
	check("water: the free start amount, 2", inv.holy_water == 2 and inv.holy_water == gs.BALANCE.start_holy_water and inv.strong_holy_water == 0)
	check("upgrades", not inv.has_sword and not inv.has_purifying_hoe and inv.hoe_uses_left == 0)
	check("hearts", progress.hearts == 5)
	check("empty land", current_scene.get_node("Farm").healing.cleansed.is_empty() and progress.healed_percent == 0.0)
	inv.seeds[&"radish"] = 1
	check("the starting list is untouched", inv.START_SEEDS[&"radish"] == 10)

	# Starting over from a real old save leaves nothing behind.
	var out := FileAccess.open("user://save.cfg", FileAccess.WRITE)
	out.store_string(FileAccess.get_file_as_string("res://tests/fixtures/save_v1.cfg"))
	out.close()
	saves.load_game()
	check("old save counts", saves.has_save() and progress.day == 2)
	saves.start_new_game()
	check("old save erased", not saves.has_save() and progress.day == 1 and saves.farm_state.is_empty())

	# A broken save isn't offered.
	out = FileAccess.open("user://save.cfg", FileAccess.WRITE)
	out.store_string("not a save")
	out.close()
	check("broken save ignored", not saves.has_save())
	title = await open_title()
	check("no Continue for it", not title.continue_button.visible)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
