class_name SoilEdges
extends TileEdges
## Draws ragged pieces of grass over tilled soil that touches untilled grass, so a field
## doesn't end in a hard square, for example around the grass left under a building.

const ATLAS := preload("res://assets/tiles/grass_edge.png")


## Call after any change to the soil, or to the ground beside it.
func refresh(ground: TileMapLayer, soil: TileMapLayer) -> void:
	var is_grass := func(cell: Vector2i) -> bool:
		return ground.get_cell_source_id(cell) == Farm.Source.GRASS and soil.get_cell_source_id(cell) == -1
	_rebuild(soil, soil.get_used_cells(), is_grass, ATLAS)
