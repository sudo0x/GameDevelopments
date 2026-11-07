extends SceneTree
## A new player gets a short story, then one goal at a time, ticked off by really playing.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.start_new_game()
	check("a new game asks for the story", gs.show_story)
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await wait(3)
	var hud: Node = main.get_node("HUD")
	var farm: Node = main.get_node("Farm")
	var guide: Label = hud.get_node("GoalGuide")
	var controls: Node = main.get_node("HUD/TouchControls")
	check("the story pauses the game", paused and guide._story != null)
	check("it tells the purpose", guide.STORY.contains("heal the island"))
	check("the story is only shown once", not gs.show_story)
	guide._close_story()
	await process_frame
	check("starting farming unpauses", not paused)

	# Every goal fits, and never names a key on a touch screen.
	var word_keys := ["Space", "press ", "Press "]
	var phone_clean := true
	for step: Array in guide.STEPS:
		for key: String in word_keys:
			phone_clean = phone_clean and not step[2].contains(key)
	check("touch goals name no keys", phone_clean)

	# Real tools tick goals off, in order.
	check("the first goal is to till", guide.text.contains("till"))
	var cell := Vector2i(26, 12)
	farm.target_cell = cell
	await wait(2)
	farm.target_cell = cell
	farm._on_tool_used(0)
	check("tilling moves on to planting", guide.text.contains("plant a seed"))
	farm.target_cell = cell
	farm._on_tool_used(2)
	check("planting moves on to watering", guide.text.contains("water your seed"))
	farm.target_cell = cell
	farm._on_tool_used(1)
	check("watering moves on to sleeping", guide.text.contains("sleep"))
	controls.set_active(true)
	check("touch screens get touch words", guide.text.contains("tap !"))
	check("the goal sits under the tool text", guide.position.y == hud.tool_label.position.y + 24.0)
	controls.set_active(false)
	check("back to keyboard words", guide.text.contains("press F"))
	gs.end_day()
	check("sleeping moves on to healing", guide.text.contains("heal"))

	# A goal done early is already ticked when its turn comes.
	gs.record_action("ship")
	gs.record_action("heal")
	check("the next open goal shows", guide.text.contains("ripe"))
	gs.record_action("harvest")
	check("a goal done early is skipped", guide.text.contains("wardthorn"))

	# The goals survive a restart.
	gs.end_day()
	var done: Array = Array(gs.guide_done).duplicate()
	main.free()
	gs._reset()
	gs.load_game()
	check("finished goals are saved", Array(gs.guide_done) == done)

	# The end of the list, and a save from before goals existed.
	gs.record_action("plant_ward")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	guide = main.get_node("HUD/GoalGuide")
	check("then the long goal", guide.text == guide.SHRINE_GOAL)
	gs.farm_state["shrine"] = true
	gs.guide_changed.emit()
	check("then keep healing", guide.text == guide.LAST_GOAL)
	gs.farm_state["shrine"] = false
	gs.guide_done.assign([gs.GUIDE_FINISHED])
	gs.guide_changed.emit()
	check("old saves skip the lessons", guide.text == guide.SHRINE_GOAL)

	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
