extends SceneTree
## The tool bar on computers: icons with number keys, the selected one highlighted, a click
## picks a tool, and it hides when touch controls are on.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func press(action: String) -> void:
	for pressed in [true, false]:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await process_frame


func click(at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = root.get_final_transform() * at
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await process_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var bar: Node2D = main.get_node("HUD/KeyToolBar")
	var player: Node = main.get_node("World/Player")
	var hud: Node = main.get_node("HUD")
	var slots: Array = bar._slots
	check("7 slots, shown on a computer", slots.size() == 7 and bar.visible)
	var numbers := bar.get_children().filter(func(n: Node) -> bool: return n is Label).map(func(l: Label) -> String: return l.text)
	check("each slot shows its key", numbers == ["1", "2", "3", "4", "5", "6", "7"])
	check("the hoe starts highlighted", slots[0].modulate != Color.WHITE and slots[1].modulate == Color.WHITE)

	await press("tool_2")
	check("a key moves the highlight", slots[1].modulate != Color.WHITE and slots[0].modulate == Color.WHITE)

	await click(slots[4].position)
	check("clicking a slot picks that tool", player.tool == 4 and slots[4].modulate != Color.WHITE)
	await click(Vector2(20, 200))
	check("clicking elsewhere changes nothing", player.tool == 4)

	# The text moved above the bar, under the hearts, so nothing overlaps.
	var label_bottom: float = hud.tool_label.get_global_rect().end.y
	check("the tool text sits well above the bar", label_bottom < 100.0)

	# Not while a menu is open.
	main.get_node("HUD/BagMenu").open()
	await click(slots[0].position)
	check("no clicks through a menu", player.tool == 4)
	main.get_node("HUD/BagMenu").close()

	# Phones have their own tappable bar.
	var controls: Node = main.get_node("HUD/TouchControls")
	controls.set_active(true)
	check("hidden with touch controls", not bar.visible)
	controls.set_active(false)
	check("back without them", bar.visible)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
