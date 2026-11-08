class_name WardTap
extends Node
## Phones: tap a ripe wardthorn itself to burst it, standing close. The HUD asks first, so a
## stray tap costs nothing.
## Storage controls (docs/28_...) also use objects this way, on phones and with a mouse click:
## the door, stall, box, workbench, wells, shrine and storage chest. The character must be close.

## How far the player can stand from the plant, in tiles.
const REACH := 2
## A finger that slides this far is doing something else.
const SLIDE_LIMIT := 12.0
## A tap this close to an object's area still counts, because fingers are wide.
const TAP_RADIUS := 10.0

## Says whether a screen position is free of the joystick and buttons. Set by the HUD.
var is_free_spot: Callable

var _farm: Farm
var _finger := -1
var _pressed_at := Vector2.ZERO
var _query := PhysicsShapeQueryParameters2D.new()


func setup(farm: Farm) -> void:
	_farm = farm
	var circle := CircleShape2D.new()
	circle.radius = TAP_RADIUS
	_query.shape = circle
	_query.collide_with_areas = true
	_query.collide_with_bodies = false


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.touch_mode:
		var click := event as InputEventMouseButton
		if GameState.carry_mode and click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_tap(click.position)
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
	var point := get_viewport().get_canvas_transform().affine_inverse() * at
	var cell := _farm.ripe_ward_at(point)
	if cell == Builder.NO_CELL:
		if GameState.carry_mode and tap_object(point):
			get_viewport().set_input_as_handled()
		return
	if Farm.tiles_apart(_farm.player_cell(), cell) > REACH:
		GameState.notice.emit("Walk closer to the wardthorn.")
		return
	_farm.burst_asked.emit(cell)


## Uses the object drawn under the tap, if the player stands close enough to reach it.
## Returns false if nothing usable was tapped.
func tap_object(point: Vector2) -> bool:
	var target := object_at(point)
	if not target:
		return false
	if not _farm.player.reach.overlaps_area(target):
		GameState.notice.emit("Walk closer to use that.")
	elif target.has_method("action_interact"):
		target.action_interact(_farm.player)
	else:
		target.interact(_farm.player)
	return true


## The usable object at a world point, or null.
func object_at(point: Vector2) -> Area2D:
	_query.transform = Transform2D(0.0, point)
	for hit in _farm.get_world_2d().direct_space_state.intersect_shape(_query):
		var area := hit["collider"] as Area2D
		if area and area.has_method("interact") and area != _farm.player.reach:
			return area
	return null
