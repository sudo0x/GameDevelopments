extends SceneTree
## Makes assets/ui/book_page.png from the parchment art. The AI art has soft, see-through parts,
## even in the middle, and the world mustn't show through behind the book's text. So only what's
## truly outside the torn edge is cleared, and everything inside it becomes solid. Run it, then
## --import:
##   godot --headless --path . --script tools/build_book_page.gd

const SOURCE := "res://art_source/ui/book_page.png"
const OUT := "res://assets/ui/book_page.png"
const SIZE := Vector2i(384, 256)
## Pixels more see-through than this can be part of the outside.
const SOLID_FROM := 0.5


func _initialize() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if not image:
		push_error("Couldn't read " + SOURCE)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_NEAREST)
	var outside := _outside(image)
	for y in SIZE.y:
		for x in SIZE.x:
			var color := image.get_pixel(x, y)
			color.a = 0.0 if outside.has(Vector2i(x, y)) else 1.0
			image.set_pixel(x, y, color)
	image.save_png(ProjectSettings.globalize_path(OUT))
	print("saved ", OUT)
	quit()


## Flood fill from the border, through see-through pixels only. A see-through patch that the
## torn edge closes off is never reached, so it stays part of the page.
func _outside(image: Image) -> Dictionary[Vector2i, bool]:
	var found: Dictionary[Vector2i, bool] = {}
	var waiting: Array[Vector2i] = []
	for x in SIZE.x:
		waiting.append(Vector2i(x, 0))
		waiting.append(Vector2i(x, SIZE.y - 1))
	for y in SIZE.y:
		waiting.append(Vector2i(0, y))
		waiting.append(Vector2i(SIZE.x - 1, y))
	while not waiting.is_empty():
		var cell: Vector2i = waiting.pop_back()
		if found.has(cell) or not Rect2i(Vector2i.ZERO, SIZE).has_point(cell):
			continue
		if image.get_pixelv(cell).a >= SOLID_FROM:
			continue
		found[cell] = true
		for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			waiting.append(cell + side)
	return found
