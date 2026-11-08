class_name Sword
extends Node2D
## The sword swing. One image is swept through an arc in code, so no animation art is needed.
## The hit lands halfway through the swing, on anything in front that has take_hit().
## The basic melee weapons (BasicWeapons) use the same swing with their own picture, reach,
## arc and speed.

const SWING_SECONDS := 0.2
## The wait after a swing, so holding the key can't hit every frame.
const COOLDOWN_SECONDS := 0.15
## How far either side of the facing direction the blade sweeps, in degrees.
const ARC := 65.0
## How far in front of the player the hit area sits, and its size.
const REACH := 24.0
const SIZE := 20.0
## The sword art's offset; the 32x32 weapon icons sit a little lower.
const SWORD_OFFSET := Vector2(0, -18)
const WEAPON_OFFSET := Vector2(0, -14)

var _busy := false
var _sword_texture: Texture2D

@onready var blade: Sprite2D = $Blade
@onready var hitbox: Area2D = $Hitbox
@onready var shape: CircleShape2D = $Hitbox/Shape.shape


func _ready() -> void:
	_sword_texture = blade.texture
	# Each player gets its own shape, since the size changes per weapon.
	shape = shape.duplicate()
	$Hitbox/Shape.shape = shape


## Does nothing, and returns false, if the last swing hasn't finished.
func swing(direction: Vector2, weapon: StringName = &"sword") -> bool:
	if _busy:
		return false
	_busy = true
	var stats: Dictionary = BasicWeapons.STATS.get(weapon, {})
	var arc := deg_to_rad(stats.get("arc", ARC))
	var swing_seconds: float = stats.get("swing", SWING_SECONDS)
	blade.texture = BasicWeapons.icon(weapon) if BasicWeapons.has(weapon) else _sword_texture
	blade.offset = WEAPON_OFFSET if BasicWeapons.has(weapon) else SWORD_OFFSET
	shape.radius = stats.get("size", SIZE)
	Audio.play(&"swing")
	hitbox.position = direction * stats.get("reach", REACH)
	# The art points up, so "up" is a rotation of zero.
	var center := direction.angle() + PI / 2.0
	blade.rotation = center - arc
	# Facing away, the blade goes behind the player.
	blade.show_behind_parent = direction == Vector2.UP
	blade.show()
	var tween := create_tween()
	tween.tween_property(blade, "rotation", center, swing_seconds / 2.0)
	tween.tween_callback(_hit.bind(direction * stats.get("push", 1.0)))
	tween.tween_property(blade, "rotation", center + arc, swing_seconds / 2.0)
	tween.tween_callback(blade.hide)
	tween.tween_interval(stats.get("cooldown", COOLDOWN_SECONDS))
	tween.tween_callback(func() -> void: _busy = false)
	return true


## `push` is the direction, made longer for weapons that knock back harder.
func _hit(push: Vector2) -> void:
	var targets: Array = hitbox.get_overlapping_bodies() + hitbox.get_overlapping_areas()
	for target: Node in targets:
		if target.has_method("take_hit"):
			target.take_hit(GameState.BALANCE.sword_damage, push)
