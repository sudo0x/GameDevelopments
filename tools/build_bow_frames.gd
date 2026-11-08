extends SceneTree
## Lines up the bow's 3 shooting frames. The AI art doesn't keep the bow in one place (in the
## last frame it sits about 3 pixels further right), so each frame is moved until its upper
## limb's right edge matches the first frame's. Then the bow doesn't jump while it's drawn.
## Run after shrinking the art with pixelize (32x32 frames):
##   godot --headless --path . --script tools/pixelize.gd -- --in art_source/items/bow_3frame.png \
##     --out art_source/items/bow_tmp.png --height 28 --frame-w 32 --frame-h 32
##   godot --headless --path . --script tools/build_bow_frames.gd

const IN := "res://art_source/items/bow_tmp.png"
const OUT := "res://assets/objects/bow_frames.png"
const FRAME := 32
const FRAMES := 3
## Rows of the upper limb, above the arrow, where only the bow itself is drawn.
const LIMB_ROWS := Vector2i(6, 11)


func _initialize() -> void:
	var sheet := Image.load_from_file(IN)
	sheet.convert(Image.FORMAT_RGBA8)
	var edges: Array[int] = []
	for f in FRAMES:
		edges.append(_limb_edge(sheet, f))
	var out := Image.create(FRAME * FRAMES, FRAME, false, Image.FORMAT_RGBA8)
	for f in FRAMES:
		var shift := edges[0] - edges[f]
		out.blit_rect(sheet, Rect2i(f * FRAME, 0, FRAME, FRAME), Vector2i(f * FRAME + shift, 0))
		print("frame %d: limb edge %d, moved %d" % [f, edges[f], shift])
	out.save_png(ProjectSettings.globalize_path(OUT))
	print("saved ", OUT)
	quit()


func _limb_edge(sheet: Image, frame: int) -> int:
	var edge := -1
	for y in range(LIMB_ROWS.x, LIMB_ROWS.y):
		for x in FRAME:
			if sheet.get_pixel(frame * FRAME + x, y).a > 0.5:
				edge = maxi(edge, x)
	return edge
