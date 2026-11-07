extends SceneTree
## Goals live in the Tasks menu, not on the screen. A new goal still shows, as a short notice.
const TASKS_AT := Vector2(28, 78)
const ACTION_AT := Vector2(596, 296)

var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await process_frame


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


func touch(at: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 1
	e.position = root.get_final_transform() * at
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func tap(at: Vector2) -> void:
	touch(at, true)
	await wait(3)
	touch(at, false)
	await wait(3)


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var progress: Node = root.get_node("Progress")
	var saves: Node = root.get_node("SaveGame")
	var notices: Array[String] = []
	saves.start_new_game()
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await wait(4)
	var hud: Node = main.get_node("HUD")
	var guide: Node = hud.get_node("GoalGuide")
	var line: Label = hud.get_node("GoalLine")
	guide.announced.connect(func(text: String) -> void: notices.append(text))
	var other_notices: Array[String] = []
	gs.notice.connect(func(text: String) -> void: other_notices.append(text))
	var tasks: Control = hud.get_node("TasksMenu")
	var controls: Node = hud.get_node("TouchControls")

	# The story comes first, then the first goal.
	check("no goal notice behind the story", notices.is_empty())
	guide._close_story()
	await wait(2)
	check("closing the story shows the first goal", notices.size() == 1 and notices[0].contains("till"))
	check("the goal line shows it", line.visible and line.text.contains("till"))
	check("goals stay out of the notices", other_notices.is_empty())
	for i in 400:
		await process_frame
	check("then it fades, leaving the screen clear", not line.visible)

	# A new goal is news, once.
	notices.clear()
	progress.record_action("till")
	check("a new goal shows as a notice", notices.size() == 1 and notices[0].contains("plant"))
	progress.record_action("till")
	root.get_node("Inventory").inventory_changed.emit()
	check("the same goal doesn't repeat", notices.size() == 1)

	# Key G.
	await press("tasks")
	check("G opens Tasks", tasks.visible and paused)
	check("it shows what to do now", tasks.list_text.contains("Now") and tasks.list_text.contains("Press R again to plant a seed"))
	check("without the word Goal", not tasks.list_text.contains("Goal:"))
	check("it shows the long goal", tasks.list_text.contains("Heal a path east"))
	check("it shows what's done", tasks.list_text.contains("Done") and tasks.list_text.contains("Till the soil"))
	check("not what isn't done", not tasks.list_text.contains("Sell your harvest"))
	await press("tasks")
	check("G closes it", not tasks.visible and not paused)
	await wait(2)

	# Phones.
	notices.clear()
	controls.set_active(true)
	await wait(3)
	check("rewording for touch isn't a new goal", notices.is_empty())
	check("phones have a Tasks button", controls._buttons["tasks"].is_visible_in_tree())
	guide.announced.emit("A long test goal that wraps across more than one line of the screen.")
	await wait(2)
	var button: Node2D = controls._buttons["tasks"]
	var button_rect := Rect2(button.position, button.texture_normal.get_size() * button.scale)
	check("the goal line clears the Tasks button", line.visible and not line.get_global_rect().intersects(button_rect))
	check("and the joystick and top right text", line.get_global_rect().end.x <= 500.0)
	notices.clear()
	await tap(TASKS_AT)
	check("one tap opens it", tasks.visible and paused)
	check("it uses touch words", tasks.list_text.contains("big button"))
	check("it clears the buttons left showing", tasks.get_global_rect().end.x <= 501.0)
	await tap(ACTION_AT)
	check("! closes it", not tasks.visible and not paused)
	await wait(2)

	# With every lesson done, it still fits, and the long goal stays.
	for step: Array in guide.STEPS:
		progress.record_action(step[0])
	await wait(2)
	tasks.open()
	await wait(3)
	var rect: Rect2 = tasks.get_global_rect()
	check("a full list fits a phone", rect.size.y <= 360.0 and rect.position.y >= 0.0)
	check("no Now section once lessons are over", not tasks.list_text.contains("Now"))
	check("the long goal stays", tasks.list_text.contains("Heal a path east"))
	tasks.close()
	await wait(2)

	# Saves from before the guide skip the lessons, and list nothing as done.
	progress.guide_done.assign([progress.GUIDE_FINISHED])
	progress.guide_changed.emit()
	tasks.open()
	await wait(2)
	check("old saves list no lessons", not tasks.list_text.contains("Done"))
	tasks.close()

	print("ALL PASS" if fails == 0 else "%d FAILED" % fails)
	quit(fails)
