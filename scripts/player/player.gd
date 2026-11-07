class_name Player
extends CharacterBody2D
## The farmer. Walks in 8 directions, shows the closest of the 4 facing poses,
## and holds the selected tool and seed.

signal tool_changed
signal tool_used(tool: Tool)
## The Action button or key was pressed. Farm works out what it means.
signal action_pressed

## Frame order in assets/player/player_idle.png.
## To add diagonal poses later, add frames to the sheet and extend this enum and _facing_for().
enum Facing { DOWN, UP, LEFT, RIGHT }
## Keys 1–7 select these, in this order.
enum Tool { HOE, WATERING_CAN, SEEDS, HAND, HOLY_WATER, BUILD, SWORD }

const TOOL_NAMES := ["Hoe", "Watering can", "Seeds", "Hand", "Holy water", "Build", "Sword"]
## In the same order as Facing.
const FACING_DIRECTIONS: Array[Vector2] = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
## The facing is kept while the walking direction is within 60° of it (cos 60° = 0.5).
const STICKY_FACING := 0.5
## After being hit, nothing can hurt the player for this long.
const SAFE_SECONDS := 1.0
const KNOCKBACK_SPEED := 200.0
## How quickly a knockback dies away, in speed per second.
const KNOCKBACK_FADE := 900.0

@export var speed: float = 90.0
## Walk animations: 4 frames each (step, pass, step, pass). Side art faces left; right is mirrored.
## A direction without walk art falls back to the idle pose with a small bob.
@export var walk_down: Texture2D
@export var walk_up: Texture2D
@export var walk_side: Texture2D
@export var walk_fps: float = 8.0
@export var bob_height: float = 2.0
@export var steps_per_second: float = 4.0

var facing: Facing = Facing.DOWN
## Last movement direction (8-way).
var look_direction: Vector2 = Vector2.DOWN
var tool: Tool = Tool.HOE
## Index into Inventory.CROPS of the seed planted with the Seeds tool.
var seed_index := 0
## Whether the Holy water tool uses the strong kind.
var strong_water := false
## Index into Inventory.BUILDINGS of the building placed with the Build tool.
var building_index := 0

var _walk_time: float = 0.0
var _safe_left := 0.0
var _knockback := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var reach: Area2D = $Reach
@onready var sword: Sword = $Sword
@onready var _idle_texture: Texture2D = sprite.texture
## Where the player wakes after fainting.
@onready var _home_position: Vector2 = global_position


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_FADE * delta)
	move_and_slide()
	_update_safe_time(delta)

	if input != Vector2.ZERO:
		look_direction = input.normalized()
		facing = _facing_for(input)
		_walk_time += delta
	else:
		_walk_time = 0.0
	_update_sprite(input != Vector2.ZERO)


## Blinks while the player can't be hurt, so they can see they're safe for a moment.
func _update_safe_time(delta: float) -> void:
	_safe_left = maxf(_safe_left - delta, 0.0)
	var blink_off := _safe_left > 0.0 and int(_safe_left * 12.0) % 2 == 0
	sprite.modulate.a = 0.35 if blink_off else 1.0


func _update_sprite(moving: bool) -> void:
	var walk := _walk_texture_for(facing) if moving else null
	if walk:
		sprite.texture = walk
		sprite.frame = int(_walk_time * walk_fps) % sprite.hframes
		sprite.flip_h = facing == Facing.RIGHT
		sprite.position.y = 0.0
	else:
		sprite.texture = _idle_texture
		sprite.frame = facing
		sprite.flip_h = false
		sprite.position.y = -roundf(absf(sin(_walk_time * PI * steps_per_second)) * bob_height)


func _walk_texture_for(dir: Facing) -> Texture2D:
	match dir:
		Facing.DOWN:
			return walk_down
		Facing.UP:
			return walk_up
	return walk_side


func _unhandled_input(event: InputEvent) -> void:
	for i in Tool.size():
		if event.is_action_pressed("tool_%d" % (i + 1)):
			tool = i as Tool
			tool_changed.emit()
	if event.is_action_pressed("seed_next"):
		_change_selection(1)
	elif event.is_action_pressed("seed_prev"):
		_change_selection(-1)
	if event.is_action_pressed("use_tool"):
		if tool == Tool.SWORD and Inventory.has_sword:
			sword.swing(FACING_DIRECTIONS[facing])
		tool_used.emit(tool)
	if event.is_action_pressed("action"):
		action_pressed.emit()
	if event.is_action_pressed("interact"):
		_interact()


## Called by creatures on contact. Does nothing during the short safe time after a hit,
## or while the day is changing.
func hurt(amount: int, direction: Vector2) -> void:
	if _safe_left > 0.0 or Progress.day_changing:
		return
	_safe_left = SAFE_SECONDS
	_knockback = direction * KNOCKBACK_SPEED
	Audio.play(&"hurt")
	Progress.take_damage(amount)


## Sends the player home. Physics interpolation is reset so they jump there instead of sliding.
func return_home() -> void:
	global_position = _home_position
	reset_physics_interpolation()


func selected_seed() -> CropData:
	return Inventory.CROPS[seed_index]


func selected_building() -> BuildingData:
	return Inventory.BUILDINGS[building_index]


## Q and E pick a building, or a kind of holy water, and a seed the rest of the time.
func _change_selection(step: int) -> void:
	if tool == Tool.BUILD:
		for i in Inventory.BUILDINGS.size():
			building_index = posmod(building_index + step, Inventory.BUILDINGS.size())
			var building := Inventory.BUILDINGS[building_index]
			if not building.starting_only or Inventory.building_count(building) > 0:
				break
	elif tool == Tool.HOLY_WATER:
		strong_water = not strong_water
	else:
		seed_index = posmod(seed_index + step, Inventory.CROPS.size())
	tool_changed.emit()


## Turns to a point and swings straight at it, because a creature can come from any side.
func swing_at(point: Vector2) -> void:
	var direction := global_position.direction_to(point)
	if direction == Vector2.ZERO:
		direction = FACING_DIRECTIONS[facing]
	if absf(direction.x) >= absf(direction.y):
		facing = Facing.RIGHT if direction.x > 0.0 else Facing.LEFT
	else:
		facing = Facing.DOWN if direction.y > 0.0 else Facing.UP
	sword.swing(direction)


## What the Action button does with an object. An object with action_interact() can treat
## Action differently from F, like the door, which asks first.
func use_nearby() -> void:
	var target := interact_target(true)
	if not target:
		return
	if target.has_method("action_interact"):
		target.action_interact(self)
	else:
		target.interact(self)


## Interacts with the first nearby area that has an interact() method (door, shipping box, shop...).
func _interact() -> void:
	var target := interact_target()
	if target:
		target.interact(self)


## The first nearby area with an interact() method, or null. With useful_only, areas whose
## can_interact() says it would do nothing right now are skipped.
func interact_target(useful_only := false) -> Area2D:
	for area in reach.get_overlapping_areas():
		if not area.has_method("interact"):
			continue
		if useful_only and area.has_method("can_interact") and not area.can_interact():
			continue
		return area
	return null


## Sticky facing: keeps the current pose while it still points the way you're walking, so a
## diagonal doesn't turn you away from what you were facing. Otherwise the closest pose wins,
## and exact diagonals use the side pose (like most top-down games).
func _facing_for(dir: Vector2) -> Facing:
	if FACING_DIRECTIONS[facing].dot(dir.normalized()) > STICKY_FACING:
		return facing
	if absf(dir.x) >= absf(dir.y):
		return Facing.RIGHT if dir.x > 0.0 else Facing.LEFT
	return Facing.DOWN if dir.y > 0.0 else Facing.UP
