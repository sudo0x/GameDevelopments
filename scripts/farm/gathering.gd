class_name Gathering
extends Node
## Places the trees and rocks and handles hitting them. Ones on cursed land stay hidden
## until that land heals, so healing is how the player finds more materials.

const SPOT_TABLE: GatherSpotTable = preload("res://data/gather/spots.tres")
const GATHERABLE_SCENE := preload("res://scenes/farm/gatherable.tscn")

## Objects by the cell they stand on.
var spots: Dictionary[Vector2i, Gatherable] = {}

var _player: Node2D


func _physics_process(_delta: float) -> void:
	for cell in spots:
		spots[cell].update_see_through(_player.global_position)


## Call after healed land is restored, so the right ones start revealed.
func populate(ground: TileMapLayer, parent: Node2D, player: Node2D) -> void:
	_player = player
	for spot in SPOT_TABLE.spots:
		var gatherable: Gatherable = GATHERABLE_SCENE.instantiate()
		gatherable.data = spot.data
		gatherable.position = parent.to_local(ground.to_global(ground.map_to_local(spot.cell))) + Vector2(0, 12)
		parent.add_child(gatherable)
		gatherable.set_revealed(ground.get_cell_source_id(spot.cell) != Farm.Source.CURSED)
		spots[spot.cell] = gatherable


func reveal(cells: Array[Vector2i]) -> void:
	for cell in cells:
		if spots.has(cell):
			spots[cell].set_revealed(true)


func can_hit(cell: Vector2i) -> bool:
	return spots.has(cell) and spots[cell].revealed and not spots[cell].gathered


func hit(cell: Vector2i) -> void:
	var gatherable := spots[cell]
	if gatherable.hit():
		var data := gatherable.data
		GameState.add_material(data.material, data.amount)
		GameState.notice.emit("+%d %s" % [data.amount, data.material.display_name])


## Text for the HUD when the player faces this cell, or empty if there's nothing to gather.
func status(cell: Vector2i) -> String:
	if not can_hit(cell):
		return ""
	return "%s: press 4, then Space to gather." % spots[cell].data.display_name
