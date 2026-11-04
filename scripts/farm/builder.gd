class_name Builder
extends Node
## Places buildings in the world and remembers them for the save file.

## What stands on each cell: the BuildingData under "data", and its node under "node".
var placed: Dictionary[Vector2i, Dictionary] = {}

var _ground: TileMapLayer
var _parent: Node2D


## `parent` must be the Y-sorted World, so the player can walk behind buildings.
func setup(ground: TileMapLayer, parent: Node2D) -> void:
	_ground = ground
	_parent = parent


## Uses one crafted building. Check Farm.can_build() first.
func place(cell: Vector2i, building: BuildingData) -> void:
	if GameState.use_building(building):
		_spawn(cell, building)


func to_state() -> Array[Dictionary]:
	var saved: Array[Dictionary] = []
	for cell in placed:
		saved.append({"cell": cell, "id": placed[cell]["data"].id})
	return saved


func restore(saved: Array) -> void:
	for entry: Dictionary in saved:
		var building := GameState.building_by_id(entry["id"])
		if building:
			_spawn(entry["cell"], building)


func _spawn(cell: Vector2i, building: BuildingData) -> void:
	var node: Node2D = building.scene.instantiate()
	node.position = _parent.to_local(_ground.to_global(_ground.map_to_local(cell) + Farm.BUILDING_BASE))
	_parent.add_child(node)
	placed[cell] = {"data": building, "node": node}
