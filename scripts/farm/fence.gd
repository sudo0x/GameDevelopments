class_name Fence
extends StaticBody2D
## A fence section. Side-on art by default; in a line going up and down (fences above or
## below, none beside) it uses the vertical art and blocks the whole tile's height, so the
## line has no gaps to walk through. Builder.fit_neighbors() calls fit() after any change.

const SIDE_TEXTURE := preload("res://assets/objects/fence.png")
const VERTICAL_TEXTURE := preload("res://assets/objects/fence_vertical.png")
## The side-on shape covers the bottom of the tile; the vertical one the whole tile.
const SIDE_SHAPE := Rect2(-16, -8, 32, 8)
const VERTICAL_SHAPE := Rect2(-6, -28, 12, 32)

var vertical := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $Shape


func _ready() -> void:
	_apply()


## `same` lists the directions (Vector2i.UP, ...) that hold another fence.
func fit(same: Array[Vector2i]) -> void:
	var beside := same.has(Vector2i.LEFT) or same.has(Vector2i.RIGHT)
	var above_or_below := same.has(Vector2i.UP) or same.has(Vector2i.DOWN)
	vertical = above_or_below and not beside
	# Fences restored from a save are fitted before World (their parent) is ready.
	if is_node_ready():
		_apply()


func _apply() -> void:
	sprite.texture = VERTICAL_TEXTURE if vertical else SIDE_TEXTURE
	var rect := VERTICAL_SHAPE if vertical else SIDE_SHAPE
	(shape.shape as RectangleShape2D).size = rect.size
	shape.position = rect.get_center()
