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


## Overnight: what was gathered gets a day closer to growing back. `is_blocked` says whether
## a cell is in use, because rubble can be farmed; those wait until the cell is free.
func advance_day(is_blocked: Callable) -> void:
	for cell in spots:
		var gatherable := spots[cell]
		if not gatherable.gathered:
			continue
		gatherable.days_until_regrow = maxi(gatherable.days_until_regrow - 1, 0)
		if gatherable.days_until_regrow == 0 and not is_blocked.call(cell):
			gatherable.regrow()


## What needs saving: only what's been gathered, since the rest starts whole.
func to_state() -> Array[Dictionary]:
	var saved: Array[Dictionary] = []
	for cell in spots:
		if spots[cell].gathered:
			saved.append({"cell": cell, "days": spots[cell].days_until_regrow})
	return saved


func restore(saved: Array) -> void:
	for entry: Dictionary in saved:
		if spots.has(entry["cell"]):
			spots[entry["cell"]].set_gathered(entry["days"])


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
		Inventory.add_material(data.material, data.amount)
		GameState.notice.emit("+%d %s" % [data.amount, data.material.display_name])


## Text for the HUD when the player faces this cell, or empty if there's nothing to say.
func status(cell: Vector2i) -> String:
	if not spots.has(cell) or not spots[cell].revealed:
		return ""
	var gatherable := spots[cell]
	var display_name := gatherable.data.display_name
	if not gatherable.gathered:
		return "%s: %s" % [display_name, GameState.controls("press 4, then Space to gather.", "tap the glove, then Use.")]
	var days := gatherable.days_until_regrow
	if days == 0:
		return ""
	return "%s: grows back in %d %s." % [display_name, days, "day" if days == 1 else "days"]
