extends Control
## Draws the player's hearts.

const SPACING := 24.0
const FULL := preload("res://assets/ui/heart_full.png")
const EMPTY := preload("res://assets/ui/heart_empty.png")


func _ready() -> void:
	GameState.hearts_changed.connect(queue_redraw)


func _draw() -> void:
	for i in GameState.BALANCE.max_hearts:
		draw_texture(FULL if i < GameState.hearts else EMPTY, Vector2(i * SPACING, 0))
