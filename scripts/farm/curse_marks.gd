class_name CurseMarks
extends Node2D
## Marks the tiles the curse will take tonight: a dark stain and pulsing corners, in the curse's
## own purple so they aren't mistaken for the tool cursor. For the curse test, the corners reuse
## the cursor's art; if the feature stays, this deserves its own art.

## Above 1, because the night mood darkens everything drawn in the world.
const COLOR := Color(1.7, 0.8, 2.0)
const STAIN := Color(0.55, 0.05, 0.85, 0.55)
const PULSE_SECONDS := 1.8
const PULSE_LOW := 0.7

var _rects: Array[Rect2] = []
var _time := 0.0
var _style := StyleBoxTexture.new()


func _ready() -> void:
	_style.texture = TileHighlight.CURSOR
	_style.modulate_color = COLOR
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_style.set_texture_margin(side, TileHighlight.CORNER)


func _process(delta: float) -> void:
	_time = fmod(_time + delta, PULSE_SECONDS)
	modulate.a = lerpf(PULSE_LOW, 1.0, 0.5 + 0.5 * cos(TAU * _time / PULSE_SECONDS))


func show_tiles(rects: Array[Rect2]) -> void:
	_rects = rects
	queue_redraw()


func _draw() -> void:
	for rect in _rects:
		draw_rect(rect, STAIN)
		draw_style_box(_style, rect)
