class_name TileHighlight
extends Node2D
## Draws the cursor around the targeted tile: white where the tool can be used, red where it
## can't. The art is four corners with nothing between them, drawn as a 9-slice, so it fits
## one tile or holy water's bigger patch with the corners staying sharp. It pulses gently.
## A guarded area is too wide for corners alone to read, so show_area() also fills it softly.

const CURSOR := preload("res://assets/ui/tile_cursor.png")
## How far each corner of the art reaches, in pixels; between the corners it's empty.
const CORNER := 12.0
## The frame sits this far outside the tile, so the corners frame it instead of covering it.
const OUTSET := 4.0
const VALID_COLOR := Color(1, 1, 1)
const INVALID_COLOR := Color(1, 0.35, 0.3)
## One slow breath, from dimmer to full and back.
const PULSE_SECONDS := 1.4
const PULSE_LOW := 0.65
const GUARD_FILL := Color(0.45, 0.95, 0.75, 0.2)
const GUARD_EDGE := Color(0.6, 1.0, 0.85, 0.6)
const UNGUARDED_FILL := Color(1, 0.35, 0.3, 0.16)
const UNGUARDED_EDGE := Color(1, 0.45, 0.4, 0.55)
const EDGE_WIDTH := 2.0

var _cell_rect := Rect2()
var _valid := false
var _filled := false
var _time := 0.0
var _style := StyleBoxTexture.new()


func _ready() -> void:
	_style.texture = CURSOR
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_style.set_texture_margin(side, CORNER)


func _process(delta: float) -> void:
	_time = fmod(_time + delta, PULSE_SECONDS)
	modulate.a = lerpf(PULSE_LOW, 1.0, 0.5 + 0.5 * cos(TAU * _time / PULSE_SECONDS))


func show_cell(rect: Rect2, valid: bool) -> void:
	_show(rect, valid, false)


## For an area a guard protects: teal when it's working, red when it isn't.
func show_area(rect: Rect2, valid: bool) -> void:
	_show(rect, valid, true)


func _show(rect: Rect2, valid: bool, filled: bool) -> void:
	if rect == _cell_rect and valid == _valid and filled == _filled:
		return
	_cell_rect = rect
	_valid = valid
	_filled = filled
	queue_redraw()


func _draw() -> void:
	if _filled:
		draw_rect(_cell_rect, GUARD_FILL if _valid else UNGUARDED_FILL)
		draw_rect(_cell_rect, GUARD_EDGE if _valid else UNGUARDED_EDGE, false, EDGE_WIDTH)
	_style.modulate_color = VALID_COLOR if _valid else INVALID_COLOR
	draw_style_box(_style, _cell_rect.grow(OUTSET))
