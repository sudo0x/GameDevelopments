class_name WetEdges
extends TileEdges
## Draws a thin ragged edge of watered soil over dry soil beside it, so wet and dry don't meet
## in a hard straight line. The edge is shallow on purpose: each watered tile must stay easy
## to tell apart, because it shows which crops still need water.

const ATLAS := preload("res://assets/tiles/wet_edge.png")


## Call after any watering, drying, tilling or untilling.
func refresh(soil: TileMapLayer) -> void:
	var is_wet := func(cell: Vector2i) -> bool:
		return soil.get_cell_source_id(cell) == Farm.Source.SOIL_WET
	_rebuild(soil, soil.get_used_cells_by_id(Farm.Source.SOIL_DRY), is_wet, ATLAS)
