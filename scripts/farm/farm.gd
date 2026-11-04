class_name Farm
extends Node2D
## The farm grid: ground and soil tiles, planted crops and the tile the player is targeting.
## Healing cursed land lives in its child node, Healing.

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

## Where a building's base sits, measured from the center of its tile.
const BUILDING_BASE := Vector2(0, 12)

@export var player_path: NodePath
## Y-sorted node that planted crops are added to, so the player can walk behind them.
@export var crops_parent_path: NodePath

var target_cell := Vector2i.ZERO
## Planted crops by cell.
var crops: Dictionary[Vector2i, Crop] = {}
var _target_status := ""
## Reused to check whether a solid object stands on a cell.
var _cell_query := PhysicsShapeQueryParameters2D.new()
## The same, but it also sees interact areas and the player, to keep them clear of buildings.
var _build_query := PhysicsShapeQueryParameters2D.new()

@onready var ground: TileMapLayer = $Ground
@onready var soil: TileMapLayer = $Soil
@onready var healing: Healing = $Healing
@onready var gathering: Gathering = $Gathering
@onready var build_preview: BuildPreview = $BuildPreview
@onready var builder: Builder = $Builder
@onready var highlight: TileHighlight = $Highlight
@onready var player: Player = get_node(player_path)
@onready var crops_parent: Node2D = get_node(crops_parent_path)


func _ready() -> void:
	var shape := RectangleShape2D.new()
	# A little smaller than a tile, so a neighbor's collision doesn't count.
	shape.size = Vector2(ground.tile_set.tile_size) - Vector2(4, 4)
	_cell_query.shape = shape
	_cell_query.exclude = [player.get_rid()]
	_build_query.shape = shape
	_build_query.collide_with_areas = true
	# Without this, the player's own reach would count as something in the way.
	# get_node, because Farm starts before Player, so player.reach isn't set yet.
	_build_query.exclude = [player.get_node("Reach").get_rid()]
	player.tool_used.connect(_on_tool_used)
	healing.land_healed.connect(gathering.reveal)
	builder.setup(ground, crops_parent)
	GameState.day_ended.connect(_on_day_ended)
	_limit_camera()
	_restore(GameState.farm_state)


func _physics_process(_delta: float) -> void:
	target_cell = target_cell_for(player)
	var tile := Vector2(ground.tile_set.tile_size)
	var rect := Rect2(ground.map_to_local(target_cell) - tile / 2.0, tile)
	if player.tool == Player.Tool.HOLY_WATER:
		rect = rect.grow(tile.x * GameState.BALANCE.cleanse_radius)
	highlight.show_cell(rect, can_use(player.tool, target_cell))
	_update_build_preview()
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


## Buildings need clean grass with nothing on it, and must keep doors, shops and the player clear.
func can_build(cell: Vector2i) -> bool:
	if ground.get_cell_source_id(cell) != Source.GRASS or is_tilled(cell) or gathering.spots.has(cell):
		return false
	_build_query.transform = _cell_transform(cell)
	return get_world_2d().direct_space_state.intersect_shape(_build_query, 1).is_empty()


## Whether the tool would do something on this cell (drives the highlight color).
func can_use(tool: Player.Tool, cell: Vector2i) -> bool:
	match tool:
		Player.Tool.HOE:
			return (is_farmable(cell) and not is_tilled(cell)) or healing.can_purify(cell)
		Player.Tool.WATERING_CAN:
			return is_tilled(cell) and not is_watered(cell)
		Player.Tool.SEEDS:
			return is_tilled(cell) and not crops.has(cell) and GameState.seed_count(player.selected_seed()) > 0
		Player.Tool.HAND:
			return (crops.has(cell) and crops[cell].is_ripe()) or gathering.can_hit(cell) or builder.placed.has(cell)
		Player.Tool.HOLY_WATER:
			return GameState.holy_water > 0 and not healing.cleansable_cells(cell).is_empty()
		Player.Tool.BUILD:
			return GameState.building_count(player.selected_building()) > 0 and can_build(cell)
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


func _update_build_preview() -> void:
	if player.tool != Player.Tool.BUILD:
		build_preview.hide()
		return
	var at := ground.map_to_local(target_cell) + BUILDING_BASE
	build_preview.show_at(player.selected_building(), at, can_use(Player.Tool.BUILD, target_cell))


func _update_target_status() -> void:
	var status := crop_status(target_cell)
	if status.is_empty():
		status = gathering.status(target_cell) + builder.status(target_cell)
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


func _has_solid_object(cell: Vector2i) -> bool:
	_cell_query.transform = _cell_transform(cell)
	return not get_world_2d().direct_space_state.intersect_shape(_cell_query, 1).is_empty()


func _cell_transform(cell: Vector2i) -> Transform2D:
	return Transform2D(0.0, ground.to_global(ground.map_to_local(cell)))


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
			if healing.is_cleansable(target_cell):
				healing.purify(target_cell)
			else:
				till(target_cell)
		Player.Tool.WATERING_CAN:
			water(target_cell)
		Player.Tool.SEEDS:
			plant(target_cell, player.selected_seed())
		Player.Tool.HAND:
			if crops.has(target_cell):
				harvest(target_cell)
			elif builder.placed.has(target_cell):
				builder.pick_up(target_cell)
			else:
				gathering.hit(target_cell)
		Player.Tool.HOLY_WATER:
			healing.cleanse(target_cell)
		Player.Tool.BUILD:
			builder.place(target_cell, player.selected_building())


## Overnight: watered crops grow one day, then all soil dries.
func _on_day_ended() -> void:
	for cell in crops:
		if is_watered(cell):
			crops[cell].grow_one_day()
	for cell in soil.get_used_cells_by_id(Source.SOIL_WET):
		till(cell)
	gathering.advance_day(is_tilled)
	_heal_from_buildings()
	_water_from_buildings()
	GameState.farm_state = _to_state()


## Wells water nearby soil for the new day. Also runs after loading, because watered soil
## isn't saved: a save is always made in the morning, so this puts the water back.
func _water_from_buildings() -> void:
	for center in builder.placed:
		var radius: int = builder.placed[center]["data"].water_radius
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var cell: Vector2i = center + Vector2i(x, y)
				if is_tilled(cell):
					water(cell)


## Each healing building pushes the curse back a little while the player sleeps.
func _heal_from_buildings() -> void:
	var healed := 0
	for cell in builder.placed:
		var radius: int = builder.placed[cell]["data"].heal_radius
		if radius > 0 and healing.heal_nearest(cell, radius):
			healed += 1
	if healed > 0:
		var tiles := "1 tile" if healed == 1 else "%d tiles" % healed
		GameState.notice.emit("Your lanterns healed %s overnight." % tiles)


## Called after the soil dries, so only tilled cells need saving, not watered ones.
func _to_state() -> Dictionary:
	var saved_crops: Array[Dictionary] = []
	for cell in crops:
		saved_crops.append({"cell": cell, "id": crops[cell].data.id, "days": crops[cell].days_grown})
	return {
		"cleansed": healing.cleansed.duplicate(),
		"tilled": soil.get_used_cells(),
		"crops": saved_crops,
		"shrine": healing.shrine.restored,
		"gathered": gathering.to_state(),
		"buildings": builder.to_state(),
	}


func _restore(state: Dictionary) -> void:
	healing.restore(state.get("cleansed", []), state.get("shrine", false))
	gathering.populate(ground, crops_parent, player)
	gathering.restore(state.get("gathered", []))
	builder.restore(state.get("buildings", []))
	for cell: Vector2i in state.get("tilled", []):
		till(cell)
	for saved: Dictionary in state.get("crops", []):
		var data := GameState.crop_by_id(saved["id"])
		if data:
			_add_crop(saved["cell"], data).set_days_grown(saved["days"])
	# Last, because restoring the soil above leaves it all dry.
	_water_from_buildings()


func _limit_camera() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	var used := ground.get_used_rect()
	var tile := ground.tile_set.tile_size
	camera.limit_left = used.position.x * tile.x
	camera.limit_top = used.position.y * tile.y
	camera.limit_right = used.end.x * tile.x
	camera.limit_bottom = used.end.y * tile.y
