extends Node
## Fills any screen with sharp pixels. It picks the biggest whole-number scale that fits the
## base size, then sizes the view to match the screen, so wider or taller screens show more of
## the world instead of black bars. Godot's "expand" aspect can't do this: it widens the view for a
## fractional scale, then the "integer" setting rounds that down and leaves bars. Windows smaller
## than the base size stay at the base size, with bars.

const BASE_SIZE := Vector2i(640, 360)


func _ready() -> void:
	get_window().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var window := get_window()
	var fits := window.size / BASE_SIZE
	var pixel_scale := maxi(mini(fits.x, fits.y), 1)
	window.content_scale_size = (window.size / pixel_scale).max(BASE_SIZE)
