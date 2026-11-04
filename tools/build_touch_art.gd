extends SceneTree
## Builds assets/ui/touch_button.png, the plain round button the touch controls use.
##
## Usage:
##   godot --headless --path <project> --script tools/build_touch_art.gd
##   then run --import so Godot picks up the new image.

const SIZE := 64
const OUTPUT := "res://assets/ui/touch_button.png"


func _init() -> void:
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(SIZE, SIZE) / 2.0
	for y in SIZE:
		for x in SIZE:
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance < SIZE / 2.0 - 3.0:
				image.set_pixel(x, y, Color(0.09, 0.07, 0.11, 0.65))
			elif distance < SIZE / 2.0:
				image.set_pixel(x, y, Color(0.75, 0.55, 0.35, 0.8))
	image.save_png(ProjectSettings.globalize_path(OUTPUT))
	print("saved ", OUTPUT)
	quit()
