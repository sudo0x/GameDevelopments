class_name Arrow
extends Area2D
## A flying arrow. It hurts the first creature it meets, stops at walls, trees and houses, and
## falls after bow_range pixels. It flies over cursed ground: only walking is blocked there.

var direction := Vector2.RIGHT
## A thrown pebble sets these; an arrow leaves them at -1 and uses the bow's numbers.
var speed := -1.0
var reach := -1.0
var texture: Texture2D
var _flown := 0.0


func _ready() -> void:
	if texture:
		$Sprite2D.texture = texture
	# The art points right.
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := (speed if speed > 0.0 else GameState.BALANCE.arrow_speed) * delta
	position += direction * step
	_flown += step
	if _flown >= (reach if reach > 0.0 else GameState.BALANCE.bow_range):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is TileMapLayer:
		return
	if body.has_method("take_hit"):
		body.take_hit(GameState.BALANCE.bow_damage, direction)
	queue_free()
