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
	# Long messages must clear the thumb controls, on the tightest screen.
	var crop_text: Label = hud.get_node("CropStatusLabel")
	crop_text.text = "Old lantern post: tap the glove, then Use to pick up."
	await wait(2)
	var text_rect: Rect2 = crop_text.get_global_rect()
	check("a long message clears the joystick", text_rect.position.x >= 138.0)
	check("a long message clears the seed arrows", text_rect.end.x <= 459.0)
	check("a long message stays above the tool bar", text_rect.end.y <= 324.0)
	check("notices sit above crop text", hud.get_node("NoticeLabel").get_global_rect().end.y <= text_rect.position.y)
	crop_text.text = ""
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
	check("joystick area reaches the tool bar on wide screens", is_equal_approx(stick.size.x, 190.0 + extra.x / 2.0))
	check("joystick area stops short of the tool bar", stick.get_global_rect().end.x < 197.0 + extra.x / 2.0)
	check("joystick area stays below the hearts", stick.position.y == 60.0)
	check("ring rests in the same corner", stick.initial_offset_ratio.is_equal_approx(Vector2(96.0 / stick.size.x, 1.0 - 74.0 / stick.size.y)))
	var pause_button: Node2D = controls.get_node("ToolBar").get_children().filter(
		func(n: Node) -> bool: return n is TouchScreenButton and n.action == "ui_cancel")[0]
	check("pause stays in the top right corner", pause_button.position == Vector2(597 + extra.x, 7))
	var bars: Sprite2D = pause_button.get_child(0)
	check("pause icon leaves the ring showing", bars.texture.get_height() * bars.scale.y <= 64.0 * 0.5)
	check("hearts use the empty hint line", hud.get_node("HeartsBar").position.y == 8.0)
	check("tool text follows the hearts", hud.get_node("ToolLabel").position.y == 28.0)
	check("day makes room for pause", is_equal_approx(hud.get_node("DayLabel").get_global_rect().end.x, screen.x - 48.0))
	check("status lines up with day", is_equal_approx(hud.get_node("StatusLabel").get_global_rect().end.x, screen.x - 48.0))
	check("notices follow the bottom edge", is_equal_approx(hud.get_node("NoticeLabel").get_global_rect().end.y, screen.y - 92.0))
	check("crop text clears the tool bar on phones", hud.get_node("CropStatusLabel").get_global_rect().end.y <= screen.y - 42.0)
	controls.set_active(false)
	check("notices clear the tool bar on computers", hud.get_node("NoticeLabel").get_global_rect().end.y <= screen.y - 42.0)
	check("crop text clears the tool bar on computers", hud.get_node("CropStatusLabel").get_global_rect().end.y <= screen.y - 42.0)
	controls.set_active(true)
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
	check("the text goes back on a computer", is_equal_approx(hud.get_node("DayLabel").get_global_rect().end.x, screen.x - 8.0))
	check("hearts go back under the hint", hud.get_node("HeartsBar").position.y == 32.0)
	root.size = Vector2i(1280, 720)
	await wait(3)
	check("back on 16:9 it's in place", keys.position.is_equal_approx(Vector2.ZERO))
	print("FAILS: ", fails)
	quit(1 if fails > 0 else 0)
