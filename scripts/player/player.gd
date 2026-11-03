class_name Player
extends CharacterBody2D
## The farmer. Walks in 8 directions, shows the closest of the 4 facing poses,
## and holds the selected tool and seed.

signal tool_changed
signal tool_used(tool: Tool)

## Frame order in assets/player/player_idle.png.
## To add diagonal poses later, add frames to the sheet and extend this enum and _facing_for().
enum Facing { DOWN, UP, LEFT, RIGHT }
## Keys 1–4 select these, in this order.
enum Tool { HOE, WATERING_CAN, SEEDS, HAND }

const TOOL_NAMES := ["Hoe", "Watering can", "Seeds", "Hand"]

@export var speed: float = 90.0
## Walking bob: a small bounce while moving, until real walk animations exist.
@export var bob_height: float = 2.0
@export var steps_per_second: float = 4.0

var facing: Facing = Facing.DOWN
## Last movement direction (8-way).
var look_direction: Vector2 = Vector2.DOWN
var tool: Tool = Tool.HOE
## Index into GameState.CROPS of the seed planted with the Seeds tool.
var seed_index := 0

var _walk_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var reach: Area2D = $Reach


func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * speed
	move_and_slide()

	if input != Vector2.ZERO:
		look_direction = input.normalized()
		facing = _facing_for(input)
		sprite.frame = facing
		_walk_time += delta
	else:
		_walk_time = 0.0
	sprite.position.y = -roundf(absf(sin(_walk_time * PI * steps_per_second)) * bob_height)


func _unhandled_input(event: InputEvent) -> void:
	for i in Tool.size():
		if event.is_action_pressed("tool_%d" % (i + 1)):
			tool = i as Tool
			tool_changed.emit()
	if event.is_action_pressed("seed_next"):
		seed_index = posmod(seed_index + 1, GameState.CROPS.size())
		tool_changed.emit()
	elif event.is_action_pressed("seed_prev"):
		seed_index = posmod(seed_index - 1, GameState.CROPS.size())
		tool_changed.emit()
	if event.is_action_pressed("use_tool"):
		tool_used.emit(tool)
	if event.is_action_pressed("interact"):
		_interact()


func selected_seed() -> CropData:
	return GameState.CROPS[seed_index]


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
