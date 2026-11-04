class_name CurseEdges
extends TileEdges
## Draws ragged pieces of curse over clean tiles that touch cursed ones.

const ATLAS := preload("res://assets/tiles/curse_edge.png")


func refresh(ground: TileMapLayer) -> void:
	var is_cursed := func(cell: Vector2i) -> bool:
		return ground.get_cell_source_id(cell) == Farm.Source.CURSED
	_rebuild(ground, ground.get_used_cells_by_id(Farm.Source.GRASS), is_cursed, ATLAS)
