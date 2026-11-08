class_name Arrow
extends Area2D
## A flying arrow. It hurts the first creature it meets, stops at walls, trees and houses, and
## falls after bow_range pixels. It flies over cursed ground: only walking is blocked there.

var direction := Vector2.RIGHT
var _flown := 0.0


func _ready() -> void:
	# The art points right.
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var step := GameState.BALANCE.arrow_speed * delta
	position += direction * step
	_flown += step
	if _flown >= GameState.BALANCE.bow_range:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is TileMapLayer:
		return
	if body.has_method("take_hit"):
		body.take_hit(GameState.BALANCE.bow_damage, direction)
	queue_free()
