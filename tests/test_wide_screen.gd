extends SceneTree
## A phone wider than 16:9 must fill with no black bars, and every control must stay at its edge.
const PHONE := Vector2i(2772, 1280)
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func tap(at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 1
		e.position = root.get_final_transform() * at
		e.pressed = pressed
		Input.parse_input_event(e)
		Input.flush_buffered_events()
		await wait(2)


func _initialize() -> void:
	_run()


func _run() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var controls: Node2D = main.get_node("HUD/TouchControls")
	var hud: Node = main.get_node("HUD")
	var player: Node = main.get_node("World/Player")
	var shop: Control = main.get_node("HUD/ShopMenu")
	controls.set_active(true)

	check("project keeps whole pixels", ProjectSettings.get_setting("display/window/stretch/scale_mode") == "integer")
	var base: Vector2 = root.get_visible_rect().size
	check("a 16:9 screen is unchanged", base == Vector2(640, 360))
	var use_button: Node2D = controls.get_children().filter(
		func(n: Node) -> bool: return n is TouchScreenButton and n.action == "use_tool")[0]
	var use_at := use_button.position

	root.size = PHONE
	await wait(3)
	var screen: Vector2 = root.get_visible_rect().size
	print("phone screen ", screen)
	check("the view grows instead of leaving bars", screen == Vector2(924, 426))
	var extra: Vector2 = screen - base
	check("Use follows the corner, moved in from the edge", use_button.position.is_equal_approx(use_at + extra - Vector2(20, 0)))
	var stick: Control = controls.get_node("Joystick")
	check("joystick is on the bottom edge", is_equal_approx(stick.get_global_rect().end.y, screen.y))
	check("joystick stays on the left", stick.position.x == 0.0)
	check("day stays in the top right", is_equal_approx(hud.get_node("DayLabel").get_global_rect().end.x, screen.x - 8.0))
	check("status stays on the right", is_equal_approx(hud.get_node("StatusLabel").get_global_rect().end.x, screen.x - 8.0))
	check("notices stay at the bottom", is_equal_approx(hud.get_node("NoticeLabel").get_global_rect().end.y, screen.y - 36.0))
	check("the fade covers the screen", hud.get_node("Fade").get_global_rect().size.is_equal_approx(screen))

	# Fingers have to land on the moved buttons, not where they were.
	await tap(Vector2(214, 340) + Vector2(extra.x / 2.0 + 36.0, extra.y))
	check("a moved tool button works", player.tool == 1)

	shop.open()
	await wait(2)
	var act_left: float = 501.0 + extra.x - 20.0
	check("a menu fits the wide screen", shop.get_global_rect().position.x >= 0.0 and shop.get_global_rect().end.x <= act_left)
	check("a menu is centered when it fits", is_equal_approx(shop.get_global_rect().get_center().x, screen.x / 2.0))
	shop.close()

	# The computer's tool bar follows too, and goes back when the window does.
	controls.set_active(false)
	var keys: Node2D = hud.get_node("KeyToolBar")
	check("the computer tool bar moves", keys.position.is_equal_approx(extra * Vector2(0.5, 1)))
	root.size = Vector2i(1280, 720)
	await wait(3)
	check("back on 16:9 it's in place", keys.position.is_equal_approx(Vector2.ZERO))
	print("FAILS: ", fails)
	quit(1 if fails > 0 else 0)
