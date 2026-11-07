extends SceneTree
## Makes assets/crops/wardthorn_ripe.png, the ripe wardthorn's 4 looping frames, from its art.
## pixelize.gd finds sprites by their shapes, so a fleck above one frame would count as a fifth,
## and each frame could shift. Here every frame is cut from the same grid, so the plant stays
## still and only the light moves. Run it, then --import:
##   godot --headless --path . --script tools/build_ward_ripe.gd

const SOURCE := "res://art_source/crops/wardthorn_ripe.png"
const OUT := "res://assets/crops/wardthorn_ripe.png"
const FRAMES := 4
const SOURCE_FRAME := Rect2i(0, 14, 543, 690)
const FRAME_SIZE := Vector2i(32, 40)
## Less solid than this is the art's soft fringe, which is cut away.
const SOLID_FROM := 0.6


func _initialize() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if not image:
		push_error("Couldn't read " + SOURCE)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	var sheet := Image.create(FRAME_SIZE.x * FRAMES, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	for i in FRAMES:
		var cut := SOURCE_FRAME
		cut.position.x += i * SOURCE_FRAME.size.x
		var frame := image.get_region(cut)
		frame.resize(FRAME_SIZE.x, FRAME_SIZE.y, Image.INTERPOLATE_LANCZOS)
		for y in FRAME_SIZE.y:
			for x in FRAME_SIZE.x:
				var color := frame.get_pixel(x, y)
				color.a = 1.0 if color.a >= SOLID_FROM else 0.0
				frame.set_pixel(x, y, color)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, FRAME_SIZE), Vector2i(i * FRAME_SIZE.x, 0))
	sheet.save_png(ProjectSettings.globalize_path(OUT))
	print("saved ", OUT)
	quit()
