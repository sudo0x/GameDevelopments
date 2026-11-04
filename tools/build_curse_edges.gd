extends SceneTree
## Builds the edge atlases that TileEdges draws, so borders aren't straight lines along the grid:
## curse_edge.png (curse over clean tiles, for CurseEdges) and grass_edge.png (grass over
## tilled soil, for SoilEdges), each from its ground texture.
##
## Usage:
##   godot --headless --path <project> --script tools/build_curse_edges.gd
##   then run --import so Godot picks up the new images.
##
## Layout: one row per direction (TileEdges.SIDES, then its corners), one column per
## 32×32 piece of the texture, so the pattern lines up with the tile next to it.

## Source texture → atlas to write.
const ATLASES := {
	"res://assets/tiles/cursed_ground.png": "res://assets/tiles/curse_edge.png",
	"res://assets/tiles/grass.png": "res://assets/tiles/grass_edge.png",
}
const TILE := 32
const TEXTURE_TILES := 4
const TEXTURE_SIZE := TILE * TEXTURE_TILES
const DIRECTIONS := 8
## Art pixels are this wide along the edge, so it looks drawn rather than noisy.
const STEP := 2
## Scattered pixels reach this far past the solid part of the edge.
const FRINGE := 4


func _init() -> void:
	for source_path: String in ATLASES:
		_build(source_path, ATLASES[source_path])
	quit()


func _build(source_path: String, output: String) -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(source_path))
	source.convert(Image.FORMAT_RGBA8)
	var pieces := TEXTURE_TILES * TEXTURE_TILES
	var atlas := Image.create(pieces * TILE, DIRECTIONS * TILE, false, Image.FORMAT_RGBA8)
	for direction in DIRECTIONS:
		for piece in pieces:
			_draw_piece(source, atlas, direction, piece)
	atlas.save_png(ProjectSettings.globalize_path(output))
	print("saved ", output, " ", atlas.get_size())


func _draw_piece(source: Image, atlas: Image, direction: int, piece: int) -> void:
	var origin := Vector2i(piece % TEXTURE_TILES, piece / TEXTURE_TILES) * TILE
	for y in TILE:
		for x in TILE:
			var at := origin + Vector2i(x, y)
			if _is_curse(direction, x, y, at):
				atlas.set_pixel(piece * TILE + x, direction * TILE + y, source.get_pixelv(at))


func _is_curse(direction: int, x: int, y: int, at: Vector2i) -> bool:
	var far := TILE - 1
	match direction:
		0:
			return _within(y, at.x, 0.0, at)
		1:
			return _within(far - x, at.y, 1.5, at)
		2:
			return _within(far - y, at.x, 3.0, at)
		3:
			return _within(x, at.y, 4.5, at)
		4:
			return _within_corner(far - x, y, at)
		5:
			return _within_corner(far - x, far - y, at)
		6:
			return _within_corner(x, far - y, at)
	return _within_corner(x, y, at)


## How far the curse reaches into the tile at this point along the edge. It uses the position
## in the 128-pixel texture and repeats with it, so neighboring tiles join up.
func _depth(along: int, phase: float) -> float:
	var t := float(along / STEP * STEP) / TEXTURE_SIZE
	return 7.0 + 3.0 * sin(TAU * 2.0 * t + phase) + 2.0 * sin(TAU * 5.0 * t + phase * 2.0)


func _within(distance: int, along: int, phase: float, at: Vector2i) -> bool:
	return _solid_or_scattered(distance - _depth(along, phase), at)


func _within_corner(x: int, y: int, at: Vector2i) -> bool:
	return _solid_or_scattered(Vector2(x, y).length() - 8.0, at)


## Solid inside the edge, then fewer and fewer stray pixels past it.
func _solid_or_scattered(past: float, at: Vector2i) -> bool:
	if past <= 0.0:
		return true
	return past < FRINGE and _chance(at) > past / FRINGE


## A repeatable random number from 0 to 1 for this texture pixel.
func _chance(at: Vector2i) -> float:
	return float(hash(at) % 1000) / 1000.0
