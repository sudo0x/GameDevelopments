extends Control
## Draws the player's hearts. Plain shapes for now, so no art is needed.

const SPACING := 16.0
const FULL_COLOR := Color(0.85, 0.2, 0.25)
const EMPTY_COLOR := Color(0.2, 0.17, 0.2, 0.8)


func _ready() -> void:
	GameState.hearts_changed.connect(queue_redraw)


func _draw() -> void:
	for i in GameState.BALANCE.max_hearts:
		_draw_heart(Vector2(i * SPACING + 7.0, 6.0), FULL_COLOR if i < GameState.hearts else EMPTY_COLOR)


func _draw_heart(at: Vector2, color: Color) -> void:
	draw_circle(at + Vector2(-3, 0), 3.5, color)
	draw_circle(at + Vector2(3, 0), 3.5, color)
	var point := PackedVector2Array([at + Vector2(-6.4, 1), at + Vector2(6.4, 1), at + Vector2(0, 8)])
	draw_colored_polygon(point, color)
