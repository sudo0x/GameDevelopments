class_name CurseEdges
extends Node2D
## Draws ragged pieces of curse over clean tiles that touch cursed ones, so the border isn't
## a straight line along the grid. Only a look: collision still follows the tiles.
## The pieces come from tools/build_curse_edges.gd.

const ATLAS := preload("res://assets/tiles/curse_edge.png")
## Row order in the atlas: these sides, then the corner between each side and the next.
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

## One entry per piece to draw: where it goes and where it is in the atlas.
var _pieces: Array[Dictionary] = []


func refresh(ground: TileMapLayer) -> void:
	_pieces.clear()
	for cell in ground.get_used_cells_by_id(Farm.Source.GRASS):
		for i in SIDES.size():
			var side := SIDES[i]
			var next_side := SIDES[(i + 1) % SIDES.size()]
			if _is_cursed(ground, cell + side):
				_add_piece(ground, cell, i)
			elif _is_cursed(ground, cell + side + next_side) and not _is_cursed(ground, cell + next_side):
				_add_piece(ground, cell, SIDES.size() + i)
	queue_redraw()


func _draw() -> void:
	for piece in _pieces:
		draw_texture_rect_region(ATLAS, piece["to"], piece["from"])


func _is_cursed(ground: TileMapLayer, cell: Vector2i) -> bool:
	return ground.get_cell_source_id(cell) == Farm.Source.CURSED


func _add_piece(ground: TileMapLayer, cell: Vector2i, row: int) -> void:
	var tile := Vector2(ground.tile_set.tile_size)
	var coords := Farm.texture_coords(cell)
	var column := coords.y * Farm.TEXTURE_TILES + coords.x
	_pieces.append({
		"to": Rect2(ground.map_to_local(cell) - tile / 2.0, tile),
		"from": Rect2(Vector2(column, row) * tile, tile),
	})
