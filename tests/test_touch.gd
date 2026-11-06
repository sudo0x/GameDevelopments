extends SceneTree
## The on-screen controls, driven by simulated fingers, including two at once.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func touch(at: Vector2, finger: int, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = finger
	e.position = root.get_final_transform() * at
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func drag(at: Vector2, finger: int) -> void:
	var e := InputEventScreenDrag.new()
	e.index = finger
	e.position = root.get_final_transform() * at
	Input.parse_input_event(e)
	Input.flush_buffered_events()


## A quick tap with one finger.
func tap(at: Vector2, finger: int = 1) -> void:
	touch(at, finger, true)
	await wait(2)
	touch(at, finger, false)
	await wait(2)


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var hud: Node = main.get_node("HUD")
	var controls: Node2D = main.get_node("HUD/TouchControls")
	var stick: Control = controls.get_node("Joystick")
	var player: Node2D = main.get_node("World/Player")
	var shop: Control = main.get_node("HUD/ShopMenu")
	var bag: Control = main.get_node("HUD/BagMenu")
	var tool_y := 340.0
	var tool_x := func(i: int) -> Vector2: return Vector2(214.0 + i * 36.0, tool_y)
	var use_at := Vector2(596, 296)
	var interact_at := Vector2(526, 322)
	var bag_at := Vector2(526, 262)
	var prev_at := Vector2(476, 300)
	var next_at := Vector2(476, 340)
	print("window ", root.size, " transform ", root.get_final_transform(), " visible ", root.get_visible_rect())

	# Hidden without a touch screen.
	check("off on this computer", not controls.visible)
	check("keyboard hint shown", hud.get_node("Hint").visible)
	touch(stick.get_global_rect().get_center() + Vector2(30, 0), 0, true)
	await wait(2)
	check("an inactive stick does nothing", not Input.is_action_pressed("move_right"))
	touch(stick.get_global_rect().get_center() + Vector2(30, 0), 0, false)

	controls.set_active(true)
	await wait(2)
	check("on", controls.visible)
	check("keyboard hint hidden", not hud.get_node("Hint").visible)
	check("tool text moved off the stick", hud.get_node("ToolLabel").position.y < 100.0)

	# The joystick, in every direction.
	var center: Vector2 = stick.get_global_rect().get_center()
	player.global_position = Vector2(600, 500)
	await wait(2)
	var from: Vector2 = player.global_position
	touch(center, 0, true)
	await wait(2)
	check("a resting thumb doesn't walk", player.global_position.distance_to(from) < 1.0)
	drag(center + Vector2(35, 0), 0)
	await wait(20)
	check("right", player.global_position.x > from.x + 20.0)
	check("facing right", player.facing == 3)
	from = player.global_position
	drag(center + Vector2(0, 35), 0)
	await wait(20)
	check("down", player.global_position.y > from.y + 20.0)
	from = player.global_position
	drag(center + Vector2(-16, 0), 0)
	await wait(20)
	check("a gentle push walks slowly", player.global_position.x < from.x - 2.0 and player.global_position.x > from.x - 25.0)
	from = player.global_position
	drag(center + Vector2(-25, -25), 0)
	await wait(20)
	check("diagonal", player.global_position.x < from.x - 10.0 and player.global_position.y < from.y - 10.0)
	touch(center, 0, false)
	await wait(2)
	from = player.global_position
	await wait(10)
	check("stops on release", player.global_position == from)
	check("nothing left pressed", not Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"))

	# The stick starts where the thumb lands, so there's room to push left even near the edge,
	# and the ring follows a thumb that slides past it.
	check("the stick follows the thumb", stick.joystick_mode == 2)
	touch(Vector2(40, 300), 0, true)
	await wait(2)
	drag(Vector2(6, 300), 0)
	await wait(2)
	check("pushing left near the edge works", Input.is_action_pressed("move_left"))
	touch(Vector2(6, 300), 0, false)
	await wait(2)
	# A long thumb slides far past the ring. Coming back a little must turn at once.
	touch(Vector2(60, 300), 0, true)
	await wait(2)
	drag(Vector2(170, 300), 0)
	await wait(2)
	check("a long slide walks right", Input.is_action_pressed("move_right"))
	drag(Vector2(100, 300), 0)
	await wait(2)
	check("a short slide back turns left", Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"))
	touch(Vector2(100, 300), 0, false)
	await wait(2)
	# High on the left side still counts.
	touch(Vector2(100, 90), 0, true)
	await wait(2)
	drag(Vector2(140, 90), 0)
	await wait(2)
	check("a thumb high on the left wakes the stick", Input.is_action_pressed("move_right"))
	touch(Vector2(140, 90), 0, false)
	await wait(2)
	touch(Vector2(320, 100), 0, true)
	await wait(2)
	check("a touch elsewhere isn't the stick", not Input.is_action_pressed("move_right"))
	touch(Vector2(320, 100), 0, false)

	# Tool bar.
	for i in 7:
		await tap(tool_x.call(i))
		check("tool button %d" % (i + 1), player.tool == i)
	await tap(tool_x.call(1))
	check("selected tool stands out", controls._tool_buttons[1].modulate != Color.WHITE and controls._tool_buttons[0].modulate == Color.WHITE)

	# Two fingers: walking and acting together.
	var used: Array = []
	player.tool_used.connect(func(t: int) -> void: used.append(t))
	touch(center, 0, true)
	drag(center + Vector2(35, 0), 0)
	await wait(4)
	await tap(use_at)
	check("Use works while walking", used.size() == 1)
	check("still walking", Input.is_action_pressed("move_right"))
	await tap(tool_x.call(3))
	check("tools change while walking", player.tool == 3)
	touch(center, 0, false)
	await wait(2)

	# Choosing seeds.
	await tap(tool_x.call(2))
	await tap(next_at)
	check("> picks the next seed", player.seed_index == 1)
	await tap(prev_at)
	check("< picks the last one", player.seed_index == 0)

	# Menus.
	var stall: Node2D = main.get_node("World/ShopStall")
	player.global_position = stall.global_position + Vector2(0, 16)
	await wait(6)
	await tap(interact_at)
	check("F opens the shop", shop.visible and paused)
	await wait(2)
	check("tool bar hides under a menu", not controls.get_node("ToolBar").visible)
	await tap(interact_at)
	check("F closes it", not shop.visible and not paused)
	await wait(2)
	check("tool bar back", controls.get_node("ToolBar").visible)
	await tap(bag_at)
	check("Bag opens", bag.visible)
	await tap(bag_at)
	check("Bag closes", not bag.visible and not paused)

	# Menus cover part of the stick's area, so it sleeps under them. A thumb held on it when a
	# menu opens must not keep walking, or jam the stick, after the menu closes.
	touch(center, 0, true)
	await wait(2)
	drag(center + Vector2(35, 0), 0)
	await wait(2)
	check("walking before the menu", Input.is_action_pressed("move_right"))
	await tap(bag_at)
	await wait(2)
	check("stick sleeps under a menu", bag.visible and not stick.visible)
	check("a menu stops the walking", not Input.is_action_pressed("move_right"))
	touch(center + Vector2(35, 0), 0, false)
	await wait(2)
	touch(center, 0, true)
	await wait(2)
	drag(center + Vector2(-35, 0), 0)
	await wait(2)
	check("a touch under a menu doesn't walk", not Input.is_action_pressed("move_left"))
	touch(center + Vector2(-35, 0), 0, false)
	await wait(2)
	await tap(bag_at)
	await wait(2)
	check("stick back after the menu", stick.visible)
	check("nothing walks after the menu", not Input.is_action_pressed("move_right"))
	touch(center, 0, true)
	await wait(2)
	drag(center + Vector2(35, 0), 0)
	await wait(2)
	check("the stick still works after the menu", Input.is_action_pressed("move_right"))
	touch(center + Vector2(35, 0), 0, false)
	await wait(2)

	# Hiding the controls with a finger down can't leave the player walking.
	touch(center, 0, true)
	drag(center + Vector2(35, 0), 0)
	await wait(2)
	controls.set_active(false)
	await wait(2)
	check("no stuck walking", not Input.is_action_pressed("move_right"))
	check("hint back", hud.get_node("Hint").visible)
	touch(center, 0, false)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
