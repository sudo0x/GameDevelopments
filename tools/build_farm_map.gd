extends SceneTree
## Builds data/tilesets/ground_tileset.tres from the ground textures and paints
## scenes/farm/ground.tscn: a clean shore surrounded by cursed ground, then the
## cursed old farmlands to the east with a few clean clearings.
## The main scene includes ground.tscn as its Ground layer.
##
## Usage (run --import first so the textures exist):
##   godot --headless --path <project> --script tools/build_farm_map.gd
##
## Running it again overwrites ground.tscn, so hand-painted changes in the editor are lost.
## The tileset is only built if it's missing: saving it again drops the UID other scenes use.
## To rebuild it, delete the .tres first, then fix any UID warnings in those scenes.

const TILESET_PATH := "res://data/tilesets/ground_tileset.tres"
const GROUND_SCENE_PATH := "res://scenes/farm/ground.tscn"
## Index = source id, matching Farm.Source.
const TEXTURES := [
	"res://assets/tiles/grass.png",
	"res://assets/tiles/cursed_ground.png",
	"res://assets/tiles/soil_dry.png",
	"res://assets/tiles/soil_wet.png",
]
const GRASS := 0
const CURSED := 1
const TILE := 32
const TEXTURE_TILES := 4

## The shore's part of the map. Saves store cells by position, so this part must never move.
const SHORE_SIZE := Vector2i(40, 26)
## The clean shore is a rough ellipse in the middle of its part of the map.
const SHORE_CENTER := Vector2(20, 13)
const SHORE_RADIUS := Vector2(15, 10)

## The old farmlands continue east of the shore, up to this size.
const MAP_SIZE := Vector2i(76, 26)
## Clean clearings in the old farmlands: center and radius. The last one is for the old shrine.
const CLEARINGS: Array[Rect2] = [
	Rect2(50, 7, 3, 2),
	Rect2(58, 18, 4, 3),
	Rect2(69, 12, 4, 4),
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/tilesets"))
	if not FileAccess.file_exists(TILESET_PATH):
		if ResourceSaver.save(_build_tile_set(), TILESET_PATH) != OK:
			push_error("Could not save " + TILESET_PATH)
			quit(1)
			return
		print("saved ", TILESET_PATH)

	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = load(TILESET_PATH)
	var grass_count := _paint_shore(ground) + _paint_old_farmlands(ground)
	print("painted ", MAP_SIZE.x * MAP_SIZE.y, " cells (", grass_count, " grass)")

	var packed := PackedScene.new()
	packed.pack(ground)
	if ResourceSaver.save(packed, GROUND_SCENE_PATH) != OK:
		push_error("Could not save " + GROUND_SCENE_PATH)
		quit(1)
		return
	print("saved ", GROUND_SCENE_PATH)
	ground.free()
	quit()


## Keep this loop and its seed as they are: changing either reshapes the shore.
func _paint_shore(ground: TileMapLayer) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var grass_count := 0
	for y in SHORE_SIZE.y:
		for x in SHORE_SIZE.x:
			var d := (Vector2(x, y) - SHORE_CENTER) / SHORE_RADIUS
			var edge := 1.0 + rng.randf_range(-0.12, 0.12)
			var source := GRASS if d.length_squared() < edge else CURSED
			if source == GRASS:
				grass_count += 1
			_paint(ground, Vector2i(x, y), source)
	return grass_count


func _paint_old_farmlands(ground: TileMapLayer) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var grass_count := 0
	for y in MAP_SIZE.y:
		for x in range(SHORE_SIZE.x, MAP_SIZE.x):
			var source := GRASS if _in_clearing(Vector2(x, y), rng) else CURSED
			if source == GRASS:
				grass_count += 1
			_paint(ground, Vector2i(x, y), source)
	return grass_count


func _in_clearing(cell: Vector2, rng: RandomNumberGenerator) -> bool:
	var edge := 1.0 + rng.randf_range(-0.12, 0.12)
	for clearing in CLEARINGS:
		if ((cell - clearing.position) / clearing.size).length_squared() < edge:
			return true
	return false


func _paint(ground: TileMapLayer, cell: Vector2i, source: int) -> void:
	ground.set_cell(cell, source, Vector2i(posmod(cell.x, TEXTURE_TILES), posmod(cell.y, TEXTURE_TILES)))


func _build_tile_set() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	var half := TILE / 2.0
	var square := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for id in TEXTURES.size():
		var source := TileSetAtlasSource.new()
		source.texture = load(TEXTURES[id])
		source.texture_region_size = Vector2i(TILE, TILE)
		tile_set.add_source(source, id)
		for y in TEXTURE_TILES:
			for x in TEXTURE_TILES:
				var coords := Vector2i(x, y)
				source.create_tile(coords)
				if id == CURSED:
					var data := source.get_tile_data(coords, 0)
					data.add_collision_polygon(0)
					data.set_collision_polygon_points(0, 0, square)
	return tile_set
