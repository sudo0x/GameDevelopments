class_name Crop
extends Node2D
## One planted crop. The origin is at the crop's base, for Y-sorting.
## Uses the stages texture from its CropData, or a simple drawn placeholder until that art exists.

const STAGES := 4
const STEM_COLOR := Color(0.36, 0.55, 0.3)

var data: CropData
## 0 = seed, 1 = sprout, 2 = growing, 3 = ripe.
var stage := 0:
	set(value):
		stage = clampi(value, 0, STAGES - 1)
		_update_look()
## Watered days so far. The crop is ripe when this reaches data.days_to_grow.
var days_grown := 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_update_look()


func is_ripe() -> bool:
	return stage == STAGES - 1


func grow_one_day() -> void:
	if not is_ripe():
		set_days_grown(days_grown + 1)


func set_days_grown(days: int) -> void:
	days_grown = days
	@warning_ignore("integer_division")
	stage = days_grown * (STAGES - 1) / data.days_to_grow


func _update_look() -> void:
	if not is_node_ready():
		return
	if data and data.stages_texture:
		sprite.texture = data.stages_texture
		sprite.hframes = STAGES
		sprite.frame = stage
		# Frames may be taller than a tile (carrot leaves); keep the bottom at the crop's base.
		sprite.offset = Vector2(0, -data.stages_texture.get_height() / 2.0)
		sprite.show()
	else:
		sprite.hide()
	queue_redraw()


func _draw() -> void:
	if data == null or data.stages_texture:
		return
	match stage:
		0:
			draw_circle(Vector2(0, -3), 2.0, Color(0.25, 0.18, 0.12))
		1:
			draw_line(Vector2(0, -2), Vector2(0, -8), STEM_COLOR, 2.0)
			draw_circle(Vector2(-2, -8), 2.0, STEM_COLOR)
			draw_circle(Vector2(2, -9), 2.0, STEM_COLOR)
		2:
			draw_line(Vector2(0, -2), Vector2(0, -14), STEM_COLOR, 2.0)
			draw_circle(Vector2(-3, -12), 3.0, STEM_COLOR)
			draw_circle(Vector2(3, -14), 3.0, STEM_COLOR)
		3:
			draw_line(Vector2(0, -6), Vector2(0, -18), STEM_COLOR, 2.0)
			draw_circle(Vector2(-3, -17), 3.0, STEM_COLOR)
			draw_circle(Vector2(3, -18), 3.0, STEM_COLOR)
			draw_circle(Vector2(0, -5), 5.0, data.color)
