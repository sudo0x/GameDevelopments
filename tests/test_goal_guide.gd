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
	var progress: Node = root.get_node("Progress")
	var saves: Node = root.get_node("SaveGame")
	saves.start_new_game()
	check("a new game asks for the story", progress.show_story)
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
	check("the story is only shown once", not progress.show_story)
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
	check("touch screens get touch words", guide.text.contains("big button"))
	check("the goal sits under the tool text", guide.position.y == hud.tool_label.position.y + 24.0)
	controls.set_active(false)
	check("back to keyboard words", guide.text.contains("press F"))
	progress.end_day()
	check("sleeping moves on to healing", guide.text.contains("heal"))

	# A goal done early is already ticked when its turn comes.
	progress.record_action("ship")
	progress.record_action("heal")
	check("the next open goal shows", guide.text.contains("ripe"))
	progress.record_action("harvest")
	check("a goal done early is skipped", guide.text.contains("wardthorn"))

	# The goals survive a restart.
	progress.end_day()
	var done: Array = Array(progress.guide_done).duplicate()
	main.free()
	saves._reset()
	saves.load_game()
	check("finished goals are saved", Array(progress.guide_done) == done)

	# The end of the list, and a save from before goals existed.
	progress.record_action("plant_ward")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	guide = main.get_node("HUD/GoalGuide")
	check("then the long goal", guide.text == guide.SHRINE_GOAL)
	saves.farm_state["shrine"] = true
	progress.guide_changed.emit()
	check("then keep healing", guide.text == guide.LAST_GOAL)
	saves.farm_state["shrine"] = false
	progress.guide_done.assign([progress.GUIDE_FINISHED])
	progress.guide_changed.emit()
	check("old saves skip the lessons", guide.text == guide.SHRINE_GOAL)

	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
