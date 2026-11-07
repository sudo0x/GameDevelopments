extends SceneTree
## Builds the wardthorn seed packet so it matches the other three: their paper, with the pod from
## art_source/items/seeds_wardthorn.png drawn on it, and its black outline softened to brown.
##
## Usage:
##   godot --headless --path <project> --script tools/build_ward_packet.gd

const PACKETS: Array[String] = ["seeds_radish", "seeds_carrot", "seeds_pumpkin"]
const PAPER_SAMPLE := Vector2i(4, 15)
## Where the pod sits in the big image, and the size and spot it gets on the packet.
const POD_SOURCE := Rect2i(310, 310, 610, 870)
const POD_SIZE := Vector2i(11, 15)
const POD_AT := Vector2i(5, 7)
const OUTLINE_COLOR := Color(0.24, 0.14, 0.1)
const DARK := 0.2


func _init() -> void:
	var images: Array[Image] = []
	for packet in PACKETS:
		images.append(_load("res://assets/items/%s.png" % packet))
	var result := _blank_packet(images)
	_draw_pod(result, _load("res://art_source/items/seeds_wardthorn.png"))
	result.save_png(ProjectSettings.globalize_path("res://assets/items/seeds_wardthorn.png"))
	print("saved assets/items/seeds_wardthorn.png")
	quit()


func _load(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image


## Each pixel comes from whichever packet is closest to plain paper there, so the three
## pictures cancel out.
func _blank_packet(images: Array[Image]) -> Image:
	var paper := images[0].get_pixelv(PAPER_SAMPLE)
	var result := images[0].duplicate()
	for y in result.get_height():
		for x in result.get_width():
			var best := images[0].get_pixel(x, y)
			for image in images:
				var c := image.get_pixel(x, y)
				if _distance(c, paper) < _distance(best, paper):
					best = c
			# Leaves that all three pictures share a spot on would otherwise show through.
			result.set_pixel(x, y, paper if best.a > 0.5 and best.g >= best.r else best)
	return result


func _distance(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)


func _draw_pod(packet: Image, source: Image) -> void:
	var block := Vector2(POD_SOURCE.size) / Vector2(POD_SIZE)
	var paper := packet.get_pixelv(PAPER_SAMPLE)
	for y in POD_SIZE.y:
		for x in POD_SIZE.x:
			var at := Vector2i(POD_SOURCE.position + Vector2i(Vector2(x, y) * block))
			var color := _block_color(source, at, Vector2i(block), paper)
			if color.a > 0.0:
				packet.set_pixelv(POD_AT + Vector2i(x, y), color)


## Dark outline turns brown, and blocks that are mostly the big image's paper are left out.
func _block_color(source: Image, at: Vector2i, size: Vector2i, paper: Color) -> Color:
	var dark := 0
	var pod := Color(0, 0, 0, 0)
	var pod_count := 0
	var total := size.x * size.y
	for y in range(at.y, at.y + size.y):
		for x in range(at.x, at.x + size.x):
			var c := source.get_pixel(x, y)
			if c.get_luminance() < DARK:
				dark += 1
			elif c.b > c.r * 0.72 or (c.r > 0.65 and c.g > 0.45 and c.b < 0.2):
				pod += c
				pod_count += 1
	if float(pod_count) / total >= 0.3:
		var color := pod / pod_count
		color.a = 1.0
		return color
	if float(dark) / total >= 0.25:
		return OUTLINE_COLOR
	return Color(0, 0, 0, 0)
