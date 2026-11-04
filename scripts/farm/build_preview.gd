class_name BuildPreview
extends Sprite2D
## A see-through copy of the selected building on the target tile: green if it can go there,
## red if it can't. Only shown while the Build tool is in hand.

const VALID_COLOR := Color(0.6, 1.0, 0.6, 0.7)
const INVALID_COLOR := Color(1.0, 0.4, 0.4, 0.6)


func show_at(building: BuildingData, at: Vector2, valid: bool) -> void:
	texture = building.preview_texture
	offset = building.preview_offset
	position = at
	modulate = VALID_COLOR if valid else INVALID_COLOR
	show()
