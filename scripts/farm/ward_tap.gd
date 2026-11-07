class_name WardTap
extends Node
## Phones: tap a ripe wardthorn itself to burst it, standing close. It's the only thing in the
## game done by touching the world, because a burst is rare, and should feel personal. The HUD
## asks first, so a stray tap costs nothing.

## How far the player can stand from the plant, in tiles.
const REACH := 2
## A finger that slides this far is doing something else.
const SLIDE_LIMIT := 12.0

## Says whether a screen position is free of the joystick and buttons. Set by the HUD.
var is_free_spot: Callable

var _farm: Farm
var _finger := -1
var _pressed_at := Vector2.ZERO


func setup(farm: Farm) -> void:
	_farm = farm


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.touch_mode:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1 and is_free_spot.is_valid() and is_free_spot.call(event.position):
			_finger = event.index
			_pressed_at = event.position
		elif not event.pressed and event.index == _finger:
			_finger = -1
			_tap(event.position)
	elif event is InputEventScreenDrag and event.index == _finger:
		if event.position.distance_to(_pressed_at) > SLIDE_LIMIT:
			_finger = -1


func _tap(at: Vector2) -> void:
	var cell := _farm.ripe_ward_at(get_viewport().get_canvas_transform().affine_inverse() * at)
	if cell == Builder.NO_CELL:
		return
	if Farm.tiles_apart(_farm.player_cell(), cell) > REACH:
		GameState.notice.emit("Walk closer to the wardthorn.")
		return
	_farm.burst_asked.emit(cell)
