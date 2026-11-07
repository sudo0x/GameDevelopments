class_name BuildingMover
extends Node
## Phones: press and hold a building, drag it, and let go to move it. The preview shows green
## or red, and letting go on red leaves it where it was. Holding, not tapping, because a stray
## tap shouldn't move things. The house and shop stall aren't in Builder.placed, so they stay.

const HOLD_SECONDS := 0.5
## A finger that slides this far before the hold ends is scrolling past, not holding.
const SLIDE_LIMIT := 12.0
const LIFTED_ALPHA := 0.35

## True while a building is being dragged.
var moving := false
## Says whether a screen position is free of the joystick and buttons. Set by the HUD.
var is_free_spot: Callable

var _farm: Farm
var _finger := -1
var _hold_left := 0.0
var _pressed_at := Vector2.ZERO
var _finger_at := Vector2.ZERO
var _from := Vector2i.ZERO
var _to := Vector2i.ZERO


func setup(farm: Farm) -> void:
	_farm = farm


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.touch_mode:
		return
	if event is InputEventScreenTouch:
		if event.pressed and _finger == -1:
			_try_hold(event)
		elif not event.pressed and event.index == _finger:
			_let_go()
	elif event is InputEventScreenDrag and event.index == _finger:
		_finger_at = event.position
		if not moving and _finger_at.distance_to(_pressed_at) > SLIDE_LIMIT:
			_cancel()


func _process(delta: float) -> void:
	if _finger == -1:
		return
	if Progress.day_changing:
		_cancel()
	elif moving:
		_show_target()
	else:
		_hold_left -= delta
		if _hold_left <= 0.0:
			_lift()


func _notification(what: int) -> void:
	# Paused nodes miss the finger lifting, so a menu opening ends the hold.
	if what == NOTIFICATION_PAUSED and _finger != -1:
		_cancel()


func _try_hold(event: InputEventScreenTouch) -> void:
	if not is_free_spot.is_valid() or not is_free_spot.call(event.position):
		return
	var cell := _farm.builder.cell_at(_world_point(event.position))
	if cell == Builder.NO_CELL:
		return
	_finger = event.index
	_from = cell
	_to = cell
	_pressed_at = event.position
	_finger_at = event.position
	_hold_left = HOLD_SECONDS


func _lift() -> void:
	moving = true
	_farm.builder.placed[_from]["node"].modulate.a = LIFTED_ALPHA
	Audio.play(&"pick_up")
	_show_target()


func _show_target() -> void:
	var ground := _farm.ground
	_to = ground.local_to_map(ground.to_local(_world_point(_finger_at)))
	var building: BuildingData = _farm.builder.placed[_from]["data"]
	_farm.build_preview.show_at(building, ground.map_to_local(_to) + Farm.BUILDING_BASE, _farm.can_build(_to))


func _let_go() -> void:
	if moving and _to != _from and _farm.can_build(_to):
		var from := _from
		_stop()
		_farm.move_building(from, _to)
		return
	_cancel()


func _cancel() -> void:
	if moving:
		_farm.builder.placed[_from]["node"].modulate.a = 1.0
	_stop()


func _stop() -> void:
	moving = false
	_finger = -1
	_farm.build_preview.hide()


## From a position on the screen to the same spot in the world, which the camera shifts.
func _world_point(screen: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen
