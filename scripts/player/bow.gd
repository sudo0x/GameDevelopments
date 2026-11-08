class_name Bow
extends Node2D
## The bow (storage controls, docs/28_...). A shot draws the bow through its 3 frames, then an
## arrow flies. The bow is turned in code to face the shot, so one row of art works every way.

const DRAW_SECONDS := 0.18
## How long the bow stays up after the arrow leaves.
const HOLD_SECONDS := 0.1
## The wait after a shot, so holding the button can't shoot every frame.
const COOLDOWN_SECONDS := 0.2
## How far from the player's middle the bow is held, and the arrow starts.
const HAND := 10.0
const ARROW_SCENE := preload("res://scenes/player/arrow.tscn")

var _busy := false

@onready var sprite: Sprite2D = $Sprite2D


## Spends one arrow. Does nothing, and returns false, while busy or with no arrows.
func shoot(direction: Vector2) -> bool:
	if _busy or not Inventory.use_arrow():
		return false
	_busy = true
	Audio.play(&"swing")
	sprite.rotation = direction.angle()
	sprite.position = direction * HAND
	# Aiming away, the bow goes behind the player.
	sprite.show_behind_parent = direction.y < -0.5
	sprite.frame = 0
	sprite.show()
	var tween := create_tween()
	tween.tween_property(sprite, "frame", sprite.hframes - 1, DRAW_SECONDS)
	tween.tween_callback(_release.bind(direction))
	tween.tween_interval(HOLD_SECONDS)
	tween.tween_callback(sprite.hide)
	tween.tween_interval(COOLDOWN_SECONDS)
	tween.tween_callback(func() -> void: _busy = false)
	return true


## The string goes back to rest, and the arrow flies from the bow. Arrows go in the y-sorted
## World, beside the player, so they pass in front of and behind things correctly.
func _release(direction: Vector2) -> void:
	sprite.frame = 0
	var arrow: Arrow = ARROW_SCENE.instantiate()
	arrow.direction = direction
	get_parent().get_parent().add_child(arrow)
	arrow.global_position = global_position + direction * HAND
