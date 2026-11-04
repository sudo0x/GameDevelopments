class_name Farm
extends Node2D
## The farm grid: ground and soil tiles, the farmable area, planted crops,
## and the tile the player is targeting.

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

## Cells where the player may till and plant.
@export var farm_area := Rect2i(13, 9, 12, 10)
@export var player_path: NodePath
## Y-sorted node that planted crops are added to, so the player can walk behind them.
@export var crops_parent_path: NodePath

var target_cell := Vector2i.ZERO
## Planted crops by cell.
var crops: Dictionary[Vector2i, Crop] = {}

@onready var ground: TileMapLayer = $Ground
@onready var soil: TileMapLayer = $Soil
@onready var highlight: TileHighlight = $Highlight
@onready var player: Player = get_node(player_path)
@onready var crops_parent: Node2D = get_node(crops_parent_path)


func _ready() -> void:
	var tile := Vector2(ground.tile_set.tile_size)
	highlight.set_area(Rect2(Vector2(farm_area.position) * tile, Vector2(farm_area.size) * tile))
	player.tool_used.connect(_on_tool_used)
	GameState.day_ended.connect(_on_day_ended)
	_limit_camera()
	_restore(GameState.farm_state)


func _physics_process(_delta: float) -> void:
	target_cell = target_cell_for(player)
	var tile := Vector2(ground.tile_set.tile_size)
	highlight.show_cell(Rect2(ground.map_to_local(target_cell) - tile / 2.0, tile), can_use(player.tool, target_cell))


## The tile in front of the player's feet, in the direction they face.
func target_cell_for(p: Player) -> Vector2i:
	var feet_cell := ground.local_to_map(ground.to_local(p.global_position + Vector2(0, -4)))
	return feet_cell + FACING_OFFSETS[p.facing]


func is_farmable(cell: Vector2i) -> bool:
	return farm_area.has_point(cell) and ground.get_cell_source_id(cell) == Source.GRASS


func is_tilled(cell: Vector2i) -> bool:
	return soil.get_cell_source_id(cell) != -1


func is_watered(cell: Vector2i) -> bool:
	return soil.get_cell_source_id(cell) == Source.SOIL_WET


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
	return false


func till(cell: Vector2i) -> void:
	soil.set_cell(cell, Source.SOIL_DRY, texture_coords(cell))


func water(cell: Vector2i) -> void:
	soil.set_cell(cell, Source.SOIL_WET, texture_coords(cell))


func plant(cell: Vector2i, data: CropData) -> void:
	if not GameState.use_seed(data):
		return
	_add_crop(cell, data)


## Picks the crop. The soil stays tilled, so the cell can be planted again.
func harvest(cell: Vector2i) -> void:
	var crop: Crop = crops[cell]
	GameState.add_harvest(crop.data)
	crops.erase(cell)
	crop.queue_free()


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
	return {"tilled": soil.get_used_cells(), "crops": saved_crops}


func _restore(state: Dictionary) -> void:
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
