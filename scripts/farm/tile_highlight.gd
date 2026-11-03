class_name TileHighlight
extends Node2D
## Draws a faint outline of the farmable area and a box around the targeted tile.

const AREA_COLOR := Color(1, 1, 1, 0.12)
const VALID_COLOR := Color(1, 1, 1, 0.85)
const INVALID_COLOR := Color(0.9, 0.3, 0.3, 0.6)

var _area_rect := Rect2()
var _cell_rect := Rect2()
var _valid := false


func set_area(area: Rect2) -> void:
	_area_rect = area
	queue_redraw()


func show_cell(rect: Rect2, valid: bool) -> void:
	if rect == _cell_rect and valid == _valid:
		return
	_cell_rect = rect
	_valid = valid
	queue_redraw()


func _draw() -> void:
	draw_rect(_area_rect, AREA_COLOR, false, 1.0)
	draw_rect(_cell_rect.grow(-1.0), VALID_COLOR if _valid else INVALID_COLOR, false, 2.0)
