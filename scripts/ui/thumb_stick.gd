class_name ThumbStick
extends Control
## The phone joystick. A thumb anywhere in this control's area wakes it, and the ring follows a
## thumb that slides past it. Godot's built-in VirtualJoystick can't keep its ring in a safe area,
## so it could run off the screen or up to the hearts. Here the ring always stays fully visible.
## It presses normal input actions, so game code doesn't know about touch.

const RING_RADIUS := 42.0
const KNOB_RADIUS := 18.0
## How far the ring's center stays from the screen edges, so even a fully pushed knob shows.
const EDGE_ROOM := RING_RADIUS + KNOB_RADIUS
const DEADZONE := 0.1
const IDLE_ALPHA := 0.7
## The art lives in the theme under this type's name.
const THEME_TYPE := &"VirtualJoystick"

## Where the ring waits between touches, in this control's own coordinates.
var rest := Vector2.ZERO:
	set(value):
		rest = value
		queue_redraw()

var _finger := -1
## The spot the push is measured from. It follows a thumb that slides past the ring, and it may
## leave the safe area, because only the drawn ring has to stay on screen.
var _anchor := Vector2.ZERO
var _thumb := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = IDLE_ALPHA


func _notification(what: int) -> void:
	# A hidden stick can't see its finger lift.
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_let_go()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var touch := make_input_local(event) as InputEventScreenTouch
		if touch.pressed and _finger == -1 and Rect2(Vector2.ZERO, size).has_point(touch.position):
			_finger = touch.index
			_anchor = touch.position
			_thumb = touch.position
			modulate.a = 1.0
			queue_redraw()
		elif not touch.pressed and touch.index == _finger:
			_let_go()
	elif event is InputEventScreenDrag and event.index == _finger:
		_thumb = (make_input_local(event) as InputEventScreenDrag).position
		var push := _thumb - _anchor
		if push.length() > RING_RADIUS:
			_anchor += push.normalized() * (push.length() - RING_RADIUS)
		_press_actions()
		queue_redraw()


## The ring's center right now, always inside the safe area.
func ring_center() -> Vector2:
	if _finger == -1:
		return rest
	return _anchor.clamp(Vector2(EDGE_ROOM, RING_RADIUS), size - Vector2(RING_RADIUS, EDGE_ROOM))


func knob_center() -> Vector2:
	return ring_center() + _push()


func _push() -> Vector2:
	if _finger == -1:
		return Vector2.ZERO
	return (_thumb - _anchor).limit_length(RING_RADIUS)


func _press_actions() -> void:
	var amount := _push() / RING_RADIUS
	if amount.length() < DEADZONE:
		amount = Vector2.ZERO
	_press(&"move_left", -amount.x)
	_press(&"move_right", amount.x)
	_press(&"move_up", -amount.y)
	_press(&"move_down", amount.y)


func _press(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _let_go() -> void:
	if _finger == -1:
		return
	_finger = -1
	modulate.a = IDLE_ALPHA
	_press_actions()
	queue_redraw()


func _draw() -> void:
	var state := "normal" if _finger == -1 else "pressed"
	var ring := Vector2(RING_RADIUS, RING_RADIUS)
	var knob := Vector2(KNOB_RADIUS, KNOB_RADIUS)
	draw_style_box(get_theme_stylebox(state + "_joystick", THEME_TYPE), Rect2(ring_center() - ring, ring * 2.0))
	draw_style_box(get_theme_stylebox(state + "_tip", THEME_TYPE), Rect2(knob_center() - knob, knob * 2.0))
