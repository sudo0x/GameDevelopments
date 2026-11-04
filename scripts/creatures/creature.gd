class_name Creature
extends CharacterBody2D
## A creature of the curse. It drifts around where it started, and chases the player who
## comes close. The origin is at its base, for Y-sorting. The floating is done in code.

enum State { WANDER, CHASE }

const FLOAT_HEIGHT := 3.0
const FLOAT_SPEED := 3.0
## How long it rests between wandering moves, at most.
const MAX_REST_SECONDS := 2.0

@export var data: CreatureData

var state := State.WANDER

var _home := Vector2.ZERO
var _wander_target := Vector2.ZERO
var _rest_left := 0.0
var _float_time := 0.0
var _player: Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_home = global_position
	_wander_target = _home
	_float_time = randf_range(0.0, TAU)
	_player = get_tree().get_first_node_in_group("player")
	sprite.texture = data.texture
	sprite.offset = Vector2(0, -data.texture.get_height() / 2.0)


func _physics_process(delta: float) -> void:
	_update_state()
	velocity = _chase_velocity() if state == State.CHASE else _wander_velocity(delta)
	move_and_slide()
	_update_look(delta)


func _update_state() -> void:
	var distance := global_position.distance_to(_player.global_position)
	if state == State.WANDER and distance < data.chase_range:
		state = State.CHASE
	elif state == State.CHASE and distance > data.lose_range:
		state = State.WANDER
		_wander_target = global_position


func _chase_velocity() -> Vector2:
	return global_position.direction_to(_player.global_position) * data.chase_speed


func _wander_velocity(delta: float) -> Vector2:
	if _rest_left > 0.0:
		_rest_left -= delta
		return Vector2.ZERO
	if global_position.distance_to(_wander_target) < 4.0 or get_slide_collision_count() > 0:
		_rest_left = randf_range(0.5, MAX_REST_SECONDS)
		_wander_target = _home + Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(0.0, data.wander_radius)
		return Vector2.ZERO
	return global_position.direction_to(_wander_target) * data.wander_speed


func _update_look(delta: float) -> void:
	_float_time += delta * FLOAT_SPEED
	sprite.position.y = -FLOAT_HEIGHT + sin(_float_time) * FLOAT_HEIGHT
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x > 0.0
