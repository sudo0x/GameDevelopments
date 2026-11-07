extends SceneTree
## Makes assets/items/purifying_hoe.png from its art. The whole hoe is long and thin, so at icon
## size its cloth and bead vanish. This keeps the head and shrinks it smoothly, because those
## are what set it apart from a plain hoe. Run it, then --import:
##   godot --headless --path . --script tools/build_hoe_icon.gd

const SOURCE := "res://art_source/items/purifying_hoe.png"
const OUT := "res://assets/items/purifying_hoe.png"
const HEAD := Rect2i(170, 40, 620, 620)
const SIZE := 24
## Less solid than this is the art's soft glow, which is cut away.
const SOLID_FROM := 0.5


func _initialize() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if not image:
		push_error("Couldn't read " + SOURCE)
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	image = image.get_region(HEAD)
	image.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	for y in SIZE:
		for x in SIZE:
			var color := image.get_pixel(x, y)
			color.a = 1.0 if color.a >= SOLID_FROM else 0.0
			image.set_pixel(x, y, color)
	image.save_png(ProjectSettings.globalize_path(OUT))
	print("saved ", OUT)
	quit()
