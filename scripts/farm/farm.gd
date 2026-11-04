class_name Farm
extends Node2D
## The farm grid: ground and soil tiles, the farmable area, planted crops,
## and the tile the player is targeting.

## What the targeted crop needs, or empty text when the player isn't facing one.
signal target_status_changed(text: String)

## Tile source ids in data/tilesets/ground_tileset.tres.
enum Source { GRASS, CURSED, SOIL_DRY, SOIL_WET }

## Each ground texture is 128×128, a 4×4 block of 32×32 tiles.
const TEXTURE_TILES := 4

const FACING_OFFSETS := {
	Player.Facing.DOWN: Vector2i.DOWN,
	Player.Facing.UP: Vector2i.UP,
	Player.Facing.LEFT: Vector2i.LEFT,
	Player.Facing.RIGHT: Vector2i.RIGHT,
}

const CROP_SCENE := preload("res://scenes/farm/crop.tscn")
const CLEANSE_EFFECT_SCENE := preload("res://scenes/farm/cleanse_effect.tscn")
const GLIMMER_SCENE := preload("res://scenes/farm/find_glimmer.tscn")

## Holy water cleanses this many tiles out from the target: 1 makes a 3×3 patch.
const CLEANSE_RADIUS := 1

## Holy water needed to restore the shrine, and how many tiles out it then heals.
const SHRINE_COST := 3
const SHRINE_RADIUS := 9

## Treasure under cursed cells, marked by a faint glimmer. Healing the cell digs it up.
## Finds aren't saved: a find is gone once its cell is in `cleansed`.
const BURIED_FINDS: Dictionary[Vector2i, Dictionary] = {
	Vector2i(38, 10): {"kind": "money", "amount": 40},
	Vector2i(42, 15): {"kind": "seeds", "crop": &"radish", "amount": 5},
	Vector2i(45, 8): {"kind": "holy_water", "amount": 2},
	Vector2i(47, 12): {"kind": "seeds", "crop": &"carrot", "amount": 3},
	Vector2i(53, 11): {"kind": "money", "amount": 80},
	Vector2i(55, 14): {"kind": "seeds", "crop": &"pumpkin", "amount": 2},
	Vector2i(63, 8): {"kind": "holy_water", "amount": 2},
	Vector2i(64, 18): {"kind": "money", "amount": 120},
}

@export var player_path: NodePath
## Y-sorted node that planted crops are added to, so the player can walk behind them.
@export var crops_parent_path: NodePath
@export var shrine_path: NodePath

var target_cell := Vector2i.ZERO
## Planted crops by cell.
var crops: Dictionary[Vector2i, Crop] = {}
## Cells healed so far. ground.tscn always starts cursed, so these are what gets saved.
var cleansed: Array[Vector2i] = []
## How many cells could ever be healed.
var _cursed_total := 0
## The glimmer over each find not dug up yet.
var _glimmers: Dictionary[Vector2i, Node2D] = {}
var _target_status := ""
## Reused to check whether a solid object stands on a cell.
var _cell_query := PhysicsShapeQueryParameters2D.new()

@onready var ground: TileMapLayer = $Ground
@onready var soil: TileMapLayer = $Soil
@onready var curse_edges: CurseEdges = $CurseEdges
@onready var highlight: TileHighlight = $Highlight
@onready var player: Player = get_node(player_path)
@onready var crops_parent: Node2D = get_node(crops_parent_path)
@onready var shrine: Shrine = get_node(shrine_path)


func _ready() -> void:
	var shape := RectangleShape2D.new()
	# A little smaller than a tile, so a neighbor's collision doesn't count.
	shape.size = Vector2(ground.tile_set.tile_size) - Vector2(4, 4)
	_cell_query.shape = shape
	_cell_query.exclude = [player.get_rid()]
	player.tool_used.connect(_on_tool_used)
	shrine.activated.connect(_on_shrine_activated)
	GameState.day_ended.connect(_on_day_ended)
	_limit_camera()
	_cursed_total = ground.get_used_cells_by_id(Source.CURSED).filter(is_cleansable).size()
	_restore(GameState.farm_state)
	_add_glimmers()
	curse_edges.refresh(ground)
	_report_progress()


func _physics_process(_delta: float) -> void:
	target_cell = target_cell_for(player)
	var tile := Vector2(ground.tile_set.tile_size)
	var rect := Rect2(ground.map_to_local(target_cell) - tile / 2.0, tile)
	if player.tool == Player.Tool.HOLY_WATER:
		rect = rect.grow(tile.x * CLEANSE_RADIUS)
	highlight.show_cell(rect, can_use(player.tool, target_cell))
	_update_target_status()


## The tile in front of the player's feet, in the direction they face.
func target_cell_for(p: Player) -> Vector2i:
	var feet_cell := ground.local_to_map(ground.to_local(p.global_position + Vector2(0, -4)))
	return feet_cell + FACING_OFFSETS[p.facing]


## Any clean grass can be farmed, unless something solid stands on it.
func is_farmable(cell: Vector2i) -> bool:
	return ground.get_cell_source_id(cell) == Source.GRASS and not _has_solid_object(cell)


func is_tilled(cell: Vector2i) -> bool:
	return soil.get_cell_source_id(cell) != -1


func is_watered(cell: Vector2i) -> bool:
	return soil.get_cell_source_id(cell) == Source.SOIL_WET


## The map's outer ring can't be healed: nothing else stops the player walking off the map.
func is_cleansable(cell: Vector2i) -> bool:
	return ground.get_cell_source_id(cell) == Source.CURSED and ground.get_used_rect().grow(-1).has_point(cell)


## The cells a cleanse centered here would heal.
func cleansable_cells(center: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(-CLEANSE_RADIUS, CLEANSE_RADIUS + 1):
		for x in range(-CLEANSE_RADIUS, CLEANSE_RADIUS + 1):
			var cell := center + Vector2i(x, y)
			if is_cleansable(cell):
				cells.append(cell)
	return cells


## Whether the tool would do something on this cell (drives the highlight color).
func can_use(tool: Player.Tool, cell: Vector2i) -> bool:
	match tool:
		Player.Tool.HOE:
			return is_farmable(cell) and not is_tilled(cell)
		Player.Tool.WATERING_CAN:
			return is_tilled(cell) and not is_watered(cell)
		Player.Tool.SEEDS:
			return is_tilled(cell) and not crops.has(cell) and GameState.seed_count(player.selected_seed()) > 0
		Player.Tool.HAND:
			return crops.has(cell) and crops[cell].is_ripe()
		Player.Tool.HOLY_WATER:
			return GameState.holy_water > 0 and not cleansable_cells(cell).is_empty()
	return false


func till(cell: Vector2i) -> void:
	soil.set_cell(cell, Source.SOIL_DRY, texture_coords(cell))


func water(cell: Vector2i) -> void:
	soil.set_cell(cell, Source.SOIL_WET, texture_coords(cell))


func plant(cell: Vector2i, data: CropData) -> void:
	if not GameState.use_seed(data):
		return
	_add_crop(cell, data)


func cleanse(center: Vector2i) -> void:
	var cells := cleansable_cells(center)
	if cells.is_empty() or not GameState.use_holy_water():
		return
	_cleanse_cells(cells, center)


## Picks the crop. The soil stays tilled, so the cell can be planted again.
func harvest(cell: Vector2i) -> void:
	var crop: Crop = crops[cell]
	GameState.add_harvest(crop.data)
	crops.erase(cell)
	crop.queue_free()


func _update_target_status() -> void:
	var status := crop_status(target_cell)
	if status != _target_status:
		_target_status = status
		target_status_changed.emit(status)


## Tells the player how a crop is doing, because growth is slow and easy to miss.
func crop_status(cell: Vector2i) -> String:
	if not crops.has(cell):
		return ""
	var crop := crops[cell]
	if crop.is_ripe():
		return "%s is ripe! Press 4 to harvest." % crop.data.display_name
	var progress := "%s: %d of %d days" % [crop.data.display_name, crop.days_grown, crop.data.days_to_grow]
	if is_watered(cell):
		return progress + ", watered. Sleep to grow."
	return progress + ", needs water."


func _cleanse_cells(cells: Array[Vector2i], center: Vector2i) -> void:
	for cell in cells:
		_heal(cell)
		if BURIED_FINDS.has(cell):
			_dig_up(cell)
	var effect: CleanseEffect = CLEANSE_EFFECT_SCENE.instantiate()
	add_child(effect)
	effect.play(cells, center, ground)
	curse_edges.refresh(ground)
	_report_progress()


func _on_shrine_activated() -> void:
	if shrine.restored:
		GameState.notice.emit("The shrine is at peace.")
	elif not GameState.use_holy_water(SHRINE_COST):
		GameState.notice.emit("The shrine needs %d holy water." % SHRINE_COST)
	else:
		shrine.restored = true
		var center := ground.local_to_map(ground.to_local(shrine.global_position))
		_cleanse_cells(_cursed_cells_around(center, SHRINE_RADIUS), center)
		GameState.notice.emit("The old shrine is restored! The land around it heals.")


## Healable cells in a circle, for a cleanse bigger than holy water's square patch.
func _cursed_cells_around(center: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var offset := Vector2i(x, y)
			if Vector2(offset).length() <= radius and is_cleansable(center + offset):
				cells.append(center + offset)
	return cells


func _heal(cell: Vector2i) -> void:
	ground.set_cell(cell, Source.GRASS, texture_coords(cell))
	cleansed.append(cell)


func _dig_up(cell: Vector2i) -> void:
	GameState.give_find(BURIED_FINDS[cell])
	_glimmers[cell].queue_free()
	_glimmers.erase(cell)


func _add_glimmers() -> void:
	for cell in BURIED_FINDS:
		if not cleansed.has(cell):
			var glimmer: Node2D = GLIMMER_SCENE.instantiate()
			glimmer.position = ground.map_to_local(cell)
			add_child(glimmer)
			_glimmers[cell] = glimmer


func _report_progress() -> void:
	GameState.set_healed_percent(100.0 * cleansed.size() / _cursed_total)


func _has_solid_object(cell: Vector2i) -> bool:
	_cell_query.transform = Transform2D(0.0, ground.to_global(ground.map_to_local(cell)))
	return not get_world_2d().direct_space_state.intersect_shape(_cell_query, 1).is_empty()


func _add_crop(cell: Vector2i, data: CropData) -> Crop:
	var crop: Crop = CROP_SCENE.instantiate()
	crop.data = data
	crop.position = crops_parent.to_local(ground.to_global(ground.map_to_local(cell))) + Vector2(0, 12)
	crops_parent.add_child(crop)
	crops[cell] = crop
	return crop


## Which 32×32 piece of a 128×128 texture a cell uses, so neighbors line up seamlessly.
static func texture_coords(cell: Vector2i) -> Vector2i:
	return Vector2i(posmod(cell.x, TEXTURE_TILES), posmod(cell.y, TEXTURE_TILES))


func _on_tool_used(tool: Player.Tool) -> void:
	if not can_use(tool, target_cell):
		return
	match tool:
		Player.Tool.HOE:
			till(target_cell)
		Player.Tool.WATERING_CAN:
			water(target_cell)
		Player.Tool.SEEDS:
			plant(target_cell, player.selected_seed())
		Player.Tool.HAND:
			harvest(target_cell)
		Player.Tool.HOLY_WATER:
			cleanse(target_cell)


## Overnight: watered crops grow one day, then all soil dries.
func _on_day_ended() -> void:
	for cell in crops:
		if is_watered(cell):
			crops[cell].grow_one_day()
	for cell in soil.get_used_cells_by_id(Source.SOIL_WET):
		till(cell)
	GameState.farm_state = _to_state()


## Called after the soil dries, so only tilled cells need saving, not watered ones.
func _to_state() -> Dictionary:
	var saved_crops: Array[Dictionary] = []
	for cell in crops:
		saved_crops.append({"cell": cell, "id": crops[cell].data.id, "days": crops[cell].days_grown})
	return {"cleansed": cleansed, "tilled": soil.get_used_cells(), "crops": saved_crops, "shrine": shrine.restored}


func _restore(state: Dictionary) -> void:
	shrine.restored = state.get("shrine", false)
	for cell: Vector2i in state.get("cleansed", []):
		_heal(cell)
	for cell: Vector2i in state.get("tilled", []):
		till(cell)
	for saved: Dictionary in state.get("crops", []):
		var data := GameState.crop_by_id(saved["id"])
		if data:
			_add_crop(saved["cell"], data).set_days_grown(saved["days"])


func _limit_camera() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	var used := ground.get_used_rect()
	var tile := ground.tile_set.tile_size
	camera.limit_left = used.position.x * tile.x
	camera.limit_top = used.position.y * tile.y
	camera.limit_right = used.end.x * tile.x
	camera.limit_bottom = used.end.y * tile.y
