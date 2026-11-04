class_name Creature
extends CharacterBody2D
## A creature of the curse. It drifts around where it started, and chases the player who
## comes close. The origin is at its base, for Y-sorting. The floating is done in code.

## It was beaten, just before it fades away.
signal defeated(creature: Creature)

enum State { WANDER, CHASE }

const FLOAT_HEIGHT := 3.0
const FLOAT_SPEED := 3.0
## How long it rests between wandering moves, at most.
const MAX_REST_SECONDS := 2.0
## It hurts the player when this close: just past where the two bodies touch.
const TOUCH_RANGE := 24.0
const KNOCKBACK_SPEED := 180.0
## How quickly a knockback dies away, in speed per second.
const KNOCKBACK_FADE := 900.0
const DEFEAT_FADE_SECONDS := 0.35

@export var data: CreatureData

var state := State.WANDER
var health := 0

var _home := Vector2.ZERO
var _wander_target := Vector2.ZERO
var _rest_left := 0.0
var _float_time := 0.0
var _player: Player
var _knockback := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	health = data.max_health
	_home = global_position
	_wander_target = _home
	_float_time = randf_range(0.0, TAU)
	_player = get_tree().get_first_node_in_group("player")
	sprite.texture = data.texture
	sprite.offset = Vector2(0, -data.texture.get_height() / 2.0)


func _physics_process(delta: float) -> void:
	_update_state()
	if _knockback != Vector2.ZERO:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_FADE * delta)
	elif state == State.CHASE:
		velocity = _chase_velocity()
	else:
		velocity = _wander_velocity(delta)
	move_and_slide()
	_touch_player()
	_update_look(delta)


## Called by the sword. A hit also makes it notice the player.
func take_hit(amount: int, direction: Vector2) -> void:
	if health <= 0:
		return
	health -= amount
	state = State.CHASE
	_knockback = direction * KNOCKBACK_SPEED
	_flash()
	if health <= 0:
		_defeat()


func _update_state() -> void:
	var distance := global_position.distance_to(_player.global_position)
	if state == State.WANDER and distance < data.chase_range:
		state = State.CHASE
	elif state == State.CHASE and distance > data.lose_range:
		state = State.WANDER
		_wander_target = global_position


## A knocked-back creature can't hurt the player, which gives them a moment to act.
func _touch_player() -> void:
	if _knockback != Vector2.ZERO:
		return
	if global_position.distance_to(_player.global_position) < TOUCH_RANGE:
		_player.hurt(data.damage, global_position.direction_to(_player.global_position))


func _flash() -> void:
	sprite.modulate = Color(2.5, 2.5, 2.5)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.15)


func _defeat() -> void:
	defeated.emit(self)
	set_physics_process(false)
	$Shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, DEFEAT_FADE_SECONDS)
	tween.tween_callback(queue_free)


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
