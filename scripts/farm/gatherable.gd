class_name Gatherable
extends StaticBody2D
## A tree or rock. Hit it with the hand tool to gather its material; what's left stays behind.
## The origin is at its base, for Y-sorting.

var data: GatherData
var hits_left := 0
var gathered := false
## Hidden until the cursed land under it heals.
var revealed := true

const SEE_THROUGH_ALPHA := 0.5

var _shake: Tween

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $Shape


func _ready() -> void:
	hits_left = data.hits
	_update_look()


func set_revealed(value: bool) -> void:
	revealed = value
	_update_look()


## Fades the art while the player is behind it, so they don't vanish behind a tree.
func update_see_through(player_feet: Vector2) -> void:
	var size := sprite.texture.get_size()
	var art := Rect2(global_position - Vector2(size.x / 2.0, size.y), size)
	sprite.modulate.a = SEE_THROUGH_ALPHA if art.has_point(player_feet) else 1.0


## Returns true on the hit that finishes it.
func hit() -> bool:
	hits_left -= 1
	_play_shake()
	if hits_left > 0:
		return false
	gathered = true
	_update_look()
	return true


func _update_look() -> void:
	# Can be called before _ready: Farm sets this up while World is still loading.
	if not is_node_ready():
		return
	sprite.texture = data.remains_texture if gathered else data.whole_texture
	# Bottom of the art at the base, whatever its size.
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
	visible = revealed
	shape.set_deferred("disabled", not revealed or (gathered and not data.remains_solid))


func _play_shake() -> void:
	if _shake:
		_shake.kill()
	sprite.position.x = 0.0
	_shake = create_tween()
	_shake.tween_property(sprite, "position:x", 2.0, 0.04)
	_shake.tween_property(sprite, "position:x", -2.0, 0.08)
	_shake.tween_property(sprite, "position:x", 0.0, 0.04)
