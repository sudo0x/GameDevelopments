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


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	check("the game opens on this screen", ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/title_screen.tscn")

	# First time: no save.
	check("no save at first", not gs.has_save())
	var title: Node = await open_title()
	check("no Continue", not title.continue_button.visible)
	check("New Game has focus", title.new_game_button.has_focus())
	check("Quit on desktop", title.quit_button.visible)
	await press("ui_accept")
	await wait_for_game()
	check("no question with nothing to lose", current_scene.name == "Main")
	check("day 1", gs.day == 1)

	# A farm in progress.
	gs.day = 9
	gs.money = 500
	gs.harvest[&"radish"] = 3
	gs.materials[&"wood"] = 7
	gs.buildings[&"fence"] = 2
	gs.holy_water = 4
	gs.strong_holy_water = 1
	gs.has_sword = true
	gs.has_purifying_hoe = true
	gs.hoe_uses_left = 2
	gs.hearts = 1
	gs.seeds[&"radish"] = 0
	gs.farm_state = {"cleansed": [Vector2i(38, 13)], "tilled": [], "crops": [], "gathered": [], "buildings": []}
	gs.save_game()
	title = await open_title()
	check("save found", gs.has_save())
	check("Continue shows the day", title.continue_button.visible and title.continue_button.text == "Continue (Day 9)")
	check("Continue has focus", title.continue_button.has_focus())
	await press("ui_accept")
	await wait_for_game()
	check("Continue starts the game", current_scene.name == "Main")
	check("the farm is there", gs.day == 9 and current_scene.get_node("Farm").healing.cleansed.size() == 1)

	# New Game asks, and the safe answer comes first.
	title = await open_title()
	title.new_game_button.pressed.emit()
	await process_frame
	check("it asks", title.confirm.visible)
	check("the warning names the farm", title.confirm_label.text.contains("Day 9"))
	check("No has focus", title.confirm_no.has_focus())
	await press("ui_accept")
	check("Enter by accident keeps the farm", not title.confirm.visible and gs.has_save() and current_scene == title)
	check("back on New Game", title.new_game_button.has_focus())
	title.new_game_button.pressed.emit()
	await process_frame
	await press("ui_cancel")
	check("Esc keeps the farm", not title.confirm.visible and gs.has_save() and gs.day == 9)

	# Really starting over.
	title.new_game_button.pressed.emit()
	await process_frame
	title.confirm_yes.pressed.emit()
	await wait_for_game()
	check("in the game", current_scene.name == "Main")
	check("save erased", not gs.has_save() and not FileAccess.file_exists(gs.SAVE_PATH))
	check("day and money", gs.day == 1 and gs.money == 0)
	check("seeds back", gs.seeds == gs.START_SEEDS)
	check("crops, materials, buildings", gs.harvest.is_empty() and gs.materials.is_empty() and gs.buildings.is_empty())
	check("water: the free start amount, 2", gs.holy_water == 2 and gs.holy_water == gs.BALANCE.start_holy_water and gs.strong_holy_water == 0)
	check("upgrades", not gs.has_sword and not gs.has_purifying_hoe and gs.hoe_uses_left == 0)
	check("hearts", gs.hearts == 5)
	check("empty land", current_scene.get_node("Farm").healing.cleansed.is_empty() and gs.healed_percent == 0.0)
	gs.seeds[&"radish"] = 1
	check("the starting list is untouched", gs.START_SEEDS[&"radish"] == 10)

	# Starting over from a real old save leaves nothing behind.
	var out := FileAccess.open("user://save.cfg", FileAccess.WRITE)
	out.store_string(FileAccess.get_file_as_string("res://tests/fixtures/save_v1.cfg"))
	out.close()
	gs.load_game()
	check("old save counts", gs.has_save() and gs.day == 2)
	gs.start_new_game()
	check("old save erased", not gs.has_save() and gs.day == 1 and gs.farm_state.is_empty())

	# A broken save isn't offered.
	out = FileAccess.open("user://save.cfg", FileAccess.WRITE)
	out.store_string("not a save")
	out.close()
	check("broken save ignored", not gs.has_save())
	title = await open_title()
	check("no Continue for it", not title.continue_button.visible)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
