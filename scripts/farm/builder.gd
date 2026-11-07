class_name Builder
extends Node
## Places buildings in the world and remembers them for the save file.
## The map's own shipping box, workbench and lantern posts count as placed buildings too,
## so they can be picked up and moved. The house and shop stall stay fixed.
## The map's lanterns are "old lantern posts": light, but no healing, as before they could move.

## What cell_at() returns when no building is there.
const NO_CELL := Vector2i(-9999, -9999)

## What stands on each cell: the BuildingData under "data", and its node under "node".
## The map's own objects also have their node name under "starting".
var placed: Dictionary[Vector2i, Dictionary] = {}

var _ground: TileMapLayer
var _parent: Node2D


## `parent` must be the Y-sorted World, so the player can walk behind buildings.
func setup(ground: TileMapLayer, parent: Node2D) -> void:
	_ground = ground
	_parent = parent


## Uses one crafted building. Check Farm.can_build() first.
func place(cell: Vector2i, building: BuildingData) -> void:
	if Inventory.use_building(building):
		_spawn(cell, building)
		fit_neighbors()


## Takes a placed building back into the bag, so a mistake costs nothing.
func pick_up(cell: Vector2i) -> void:
	var entry := placed[cell]
	placed.erase(cell)
	entry["node"].queue_free()
	fit_neighbors()
	Inventory.add_building(entry["data"])
	GameState.notice.emit("Picked up: %s" % entry["data"].display_name)


## Moves a building to a free cell, without it passing through the bag. A map object becomes
## a saved one, so it stays where the player put it. Check Farm.can_build() first.
func move(from: Vector2i, to: Vector2i) -> void:
	var entry := placed[from]
	placed.erase(from)
	entry["node"].queue_free()
	_spawn(to, entry["data"])
	fit_neighbors()


## The cell of the building drawn at this world point, or NO_CELL. Buildings are taller than
## their tile, so this uses the art, and the one in front wins.
func cell_at(point: Vector2) -> Vector2i:
	var found := NO_CELL
	var front := -INF
	for cell in placed:
		var node: Node2D = placed[cell]["node"]
		var data: BuildingData = placed[cell]["data"]
		var size := data.preview_texture.get_size()
		var art := Rect2(node.global_position + data.preview_offset - size / 2.0, size)
		if art.has_point(point) and node.global_position.y > front:
			found = cell
			front = node.global_position.y
	return found


## Text for the HUD when the player faces this cell, or empty if nothing's built there.
func status(cell: Vector2i) -> String:
	if not placed.has(cell):
		return ""
	var how := GameState.controls("press 4, then Space to pick up.", "hold it to move it.")
	return "%s: %s" % [placed[cell]["data"].display_name, how]


## Buildings the player placed. The map's own objects are saved by starting_left() instead.
func to_state() -> Array[Dictionary]:
	var saved: Array[Dictionary] = []
	for cell in placed:
		if not placed[cell].has("starting"):
			saved.append({"cell": cell, "id": placed[cell]["data"].id})
	return saved


## Names of the map's own objects still where the map put them.
func starting_left() -> Array[StringName]:
	var names: Array[StringName] = []
	for cell in placed:
		if placed[cell].has("starting"):
			names.append(placed[cell]["starting"])
	return names


## Takes charge of the map's own movable objects. `left` is starting_left() from the save;
## null (a new game, or a save from before objects could move) keeps them all.
func adopt_starting(left: Variant) -> void:
	for node in _parent.get_children():
		var building := _building_for(node)
		if not building:
			continue
		if left != null and not (left as Array).has(node.name):
			# Picked up in an earlier game: if it was placed again, restore() brings it back.
			_parent.remove_child(node)
			node.queue_free()
			continue
		var cell := _ground.local_to_map(_ground.to_local(_parent.to_global(node.position)) - Farm.BUILDING_BASE)
		placed[cell] = {"data": building, "node": node, "starting": node.name}


func restore(saved: Array) -> void:
	for entry: Dictionary in saved:
		var building := Inventory.building_by_id(entry["id"])
		if building:
			_spawn(entry["cell"], building)
	fit_neighbors()


## Lets buildings that join up (fences) match their neighbors of the same kind.
## Each one with a fit() method gets the directions that hold the same building.
func fit_neighbors() -> void:
	for cell in placed:
		var node: Node = placed[cell]["node"]
		if not node.has_method("fit"):
			continue
		var same: Array[Vector2i] = []
		for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if placed.has(cell + side) and placed[cell + side]["data"] == placed[cell]["data"]:
				same.append(side)
		node.fit(same)


## Only starting-only kinds, so the map's lanterns are old ones that don't heal.
func _building_for(node: Node) -> BuildingData:
	for building in Inventory.BUILDINGS:
		if building.starting_only and node.scene_file_path == building.scene.resource_path:
			return building
	return null


func _spawn(cell: Vector2i, building: BuildingData) -> void:
	var node: Node2D = building.scene.instantiate()
	node.position = _parent.to_local(_ground.to_global(_ground.map_to_local(cell) + Farm.BUILDING_BASE))
	_parent.add_child(node)
	placed[cell] = {"data": building, "node": node}
