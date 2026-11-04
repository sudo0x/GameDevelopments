class_name Sword
extends Node2D
## The sword swing. One image is swept through an arc in code, so no animation art is needed.
## The hit lands halfway through the swing, on anything in front that has take_hit().

const SWING_SECONDS := 0.2
## The wait after a swing, so holding the key can't hit every frame.
const COOLDOWN_SECONDS := 0.15
## How far either side of the facing direction the blade sweeps.
const ARC := deg_to_rad(65.0)
## How far in front of the player the hit area sits.
const REACH := 24.0

var _busy := false

@onready var blade: Sprite2D = $Blade
@onready var hitbox: Area2D = $Hitbox


## Does nothing if the last swing hasn't finished.
func swing(direction: Vector2) -> void:
	if _busy:
		return
	_busy = true
	hitbox.position = direction * REACH
	# The art points up, so "up" is a rotation of zero.
	var center := direction.angle() + PI / 2.0
	blade.rotation = center - ARC
	# Facing away, the blade goes behind the player.
	blade.show_behind_parent = direction == Vector2.UP
	blade.show()
	var tween := create_tween()
	tween.tween_property(blade, "rotation", center, SWING_SECONDS / 2.0)
	tween.tween_callback(_hit.bind(direction))
	tween.tween_property(blade, "rotation", center + ARC, SWING_SECONDS / 2.0)
	tween.tween_callback(blade.hide)
	tween.tween_interval(COOLDOWN_SECONDS)
	tween.tween_callback(func() -> void: _busy = false)


func _hit(direction: Vector2) -> void:
	var targets: Array = hitbox.get_overlapping_bodies() + hitbox.get_overlapping_areas()
	for target: Node in targets:
		if target.has_method("take_hit"):
			target.take_hit(GameState.BALANCE.sword_damage, direction)
