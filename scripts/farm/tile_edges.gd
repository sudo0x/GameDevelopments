class_name TileEdges
extends Node2D
## Draws ragged pieces of one kind of ground over the tiles beside it, so a border isn't a
## straight line along the grid. Only a look: collision still follows the tiles.
## The atlases come from tools/build_curse_edges.gd: one row per direction, one column per
## 32×32 piece of the 128×128 texture, so the pattern lines up with the tile next to it.

## Row order in an atlas: these sides, then the corner between each side and the next.
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

## One entry per piece to draw: where it goes and where it is in the atlas.
var _pieces: Array[Dictionary] = []
var _atlas: Texture2D


## Gives each cell in `cells` a piece on every side (or corner) where `is_other` is true.
func _rebuild(layer: TileMapLayer, cells: Array[Vector2i], is_other: Callable, atlas: Texture2D) -> void:
	_atlas = atlas
	_pieces.clear()
	for cell in cells:
		for i in SIDES.size():
			var side := SIDES[i]
			var next_side := SIDES[(i + 1) % SIDES.size()]
			if is_other.call(cell + side):
				_add_piece(layer, cell, i)
			elif is_other.call(cell + side + next_side) and not is_other.call(cell + next_side):
				_add_piece(layer, cell, SIDES.size() + i)
	queue_redraw()


func _draw() -> void:
	for piece in _pieces:
		draw_texture_rect_region(_atlas, piece["to"], piece["from"])


func _add_piece(layer: TileMapLayer, cell: Vector2i, row: int) -> void:
	var tile := Vector2(layer.tile_set.tile_size)
	var coords := Farm.texture_coords(cell)
	var column := coords.y * Farm.TEXTURE_TILES + coords.x
	_pieces.append({
		"to": Rect2(layer.map_to_local(cell) - tile / 2.0, tile),
		"from": Rect2(Vector2(column, row) * tile, tile),
	})
