class_name Player
extends CharacterBody2D
## The farmer. Walks in 8 directions, shows the closest of the 4 facing poses,
## and holds the selected tool and seed.

signal tool_changed
signal tool_used(tool: Tool)

## Frame order in assets/player/player_idle.png.
## To add diagonal poses later, add frames to the sheet and extend this enum and _facing_for().
enum Facing { DOWN, UP, LEFT, RIGHT }
## Keys 1–7 select these, in this order.
enum Tool { HOE, WATERING_CAN, SEEDS, HAND, HOLY_WATER, BUILD, SWORD }

const TOOL_NAMES := ["Hoe", "Watering can", "Seeds", "Hand", "Holy water", "Build", "Sword"]
## In the same order as Facing.
const FACING_DIRECTIONS: Array[Vector2] = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
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
## Index into GameState.CROPS of the seed planted with the Seeds tool.
var seed_index := 0
## Whether the Holy water tool uses the strong kind.
var strong_water := false
## Index into GameState.BUILDINGS of the building placed with the Build tool.
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
		if tool == Tool.SWORD and GameState.has_sword:
			sword.swing(FACING_DIRECTIONS[facing])
		tool_used.emit(tool)
	if event.is_action_pressed("interact"):
		_interact()


## Called by creatures on contact. Does nothing during the short safe time after a hit,
## or while the day is changing.
func hurt(amount: int, direction: Vector2) -> void:
	if _safe_left > 0.0 or GameState.day_changing:
		return
	_safe_left = SAFE_SECONDS
	_knockback = direction * KNOCKBACK_SPEED
	Audio.play(&"hurt")
	GameState.take_damage(amount)


## Sends the player home. Physics interpolation is reset so they jump there instead of sliding.
func return_home() -> void:
	global_position = _home_position
	reset_physics_interpolation()


func selected_seed() -> CropData:
	return GameState.CROPS[seed_index]


func selected_building() -> BuildingData:
	return GameState.BUILDINGS[building_index]


## Q and E pick a building, or a kind of holy water, and a seed the rest of the time.
func _change_selection(step: int) -> void:
	if tool == Tool.BUILD:
		for i in GameState.BUILDINGS.size():
			building_index = posmod(building_index + step, GameState.BUILDINGS.size())
			var building := GameState.BUILDINGS[building_index]
			if not building.starting_only or GameState.building_count(building) > 0:
				break
	elif tool == Tool.HOLY_WATER:
		strong_water = not strong_water
	else:
		seed_index = posmod(seed_index + step, GameState.CROPS.size())
	tool_changed.emit()


## Interacts with the first nearby area that has an interact() method (door, later shipping box and shop).
func _interact() -> void:
	for area in reach.get_overlapping_areas():
		if area.has_method("interact"):
			area.interact(self)
			return


## Diagonals use the side pose (like most top-down games).
func _facing_for(dir: Vector2) -> Facing:
	if absf(dir.x) >= absf(dir.y):
		return Facing.RIGHT if dir.x > 0.0 else Facing.LEFT
	return Facing.DOWN if dir.y > 0.0 else Facing.UP
