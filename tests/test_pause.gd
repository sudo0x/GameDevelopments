extends SceneTree
## The pause menu: Esc opens it, Settings and Back to title work, and leaving throws away
## the unsaved day. On phones a pause button sends the same Esc action.
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


func tap(at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 1
		e.position = root.get_final_transform() * at
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		for i in 2:
			await process_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.money = 50
	gs.save_game()
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var pause: Node = main.get_node("HUD/PauseMenu")
	var settings: Node = main.get_node("HUD/SettingsMenu")
	var bag: Node = main.get_node("HUD/BagMenu")

	await press("ui_cancel")
	check("Esc pauses", pause.visible and paused)
	check("Resume has focus", pause.resume_button.has_focus())
	await press("ui_cancel")
	check("Esc again resumes", not pause.visible and not paused)

	# A finger on the phone's pause button opens it too.
	var controls: Node = main.get_node("HUD/TouchControls")
	controls.set_active(true)
	await process_frame
	await tap(Vector2(614, 24))
	check("the pause button pauses", pause.visible and paused)
	pause.resume_button.pressed.emit()
	# The Use button shows the selected tool, so you can see what it will do.
	await press("tool_7")
	check("Use shows the sword", controls._use_icon.texture == controls.SWORD_ICON)
	await press("tool_2")
	var shown: Texture2D = controls._use_icon.texture
	check("then the watering can", shown is AtlasTexture and (shown as AtlasTexture).region == controls.tool_icon(1).region)
	controls.set_active(false)
	check("Resume button resumes", not pause.visible and not paused)

	# Esc closes another open menu, without opening this one.
	bag.open()
	await press("ui_cancel")
	check("Esc closes the bag only", not bag.visible and not pause.visible and not paused)

	# Not while the screen fades to the next day.
	gs.day_changing = true
	await press("ui_cancel")
	check("no pause while the day changes", not pause.visible)
	gs.day_changing = false

	# Settings take the menu's place, and Esc comes back to it.
	await press("ui_cancel")
	pause.settings_button.pressed.emit()
	await process_frame
	check("settings open, still paused", settings.visible and not pause.visible and paused)
	settings.find_child("MusicDown", true, false).pressed.emit()
	await press("ui_cancel")
	check("Esc goes back to the pause menu", not settings.visible and pause.visible and paused)

	# Back to title asks first, with No focused.
	pause.title_button.pressed.emit()
	await process_frame
	check("asks first", pause.confirm.visible and not pause.buttons.visible and pause.confirm_no.has_focus())
	await press("ui_cancel")
	check("Esc says no", not pause.confirm.visible and pause.buttons.visible and pause.visible)
	pause.title_button.pressed.emit()
	pause.confirm_no.pressed.emit()
	check("No stays", pause.visible and not pause.confirm.visible)

	# Leaving throws away today: money earned since the save is gone.
	gs.money = 999
	gs.shipped[&"radish"] = 3
	gs.hearts = 1
	pause.title_button.pressed.emit()
	pause.confirm_yes.pressed.emit()
	await process_frame
	await process_frame
	check("unpaused", not paused)
	check("back to the saved morning", gs.money == 50 and gs.shipped.is_empty() and gs.hearts == gs.BALANCE.max_hearts)
	check("title screen shown", root.get_node_or_null("TitleScreen") != null)

	# Phones: the pause button hides under menus like the tool bar.
	var pause_buttons: Array = controls.get_node("ToolBar").get_children().filter(func(b: Node) -> bool: return b is TouchScreenButton and b.action == "ui_cancel")
	check("pause button on the tool bar layer", pause_buttons.size() == 1)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
