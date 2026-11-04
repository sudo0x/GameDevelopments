class_name CleanseEffect
extends Node2D
## The healing animation. The land is already healed underneath: this draws the old cursed
## tiles on top and fades them out from the center, with a flash of light and rising sparkles.

## Seconds before the fade reaches the next tile out from the center.
const RING_DELAY := 0.1
const FADE_SECONDS := 0.3
const LIGHT_ENERGY := 1.6

@onready var light: PointLight2D = $Light
@onready var sparkles: CPUParticles2D = $Sparkles


## Removes itself when finished, so it works for a small patch or a much larger cleanse.
func play(cells: Array[Vector2i], center: Vector2i, ground: TileMapLayer) -> void:
	position = ground.map_to_local(center)
	var cursed: TileSetAtlasSource = ground.tile_set.get_source(Farm.Source.CURSED)
	var tile := Vector2(ground.tile_set.tile_size)
	var reach := 0.0
	var tween := create_tween().set_parallel()
	for cell in cells:
		var distance := Vector2(cell - center).length()
		reach = maxf(reach, distance)
		var piece := Sprite2D.new()
		piece.texture = cursed.texture
		piece.region_enabled = true
		piece.region_rect = Rect2(Vector2(Farm.texture_coords(cell)) * tile, tile)
		piece.position = ground.map_to_local(cell) - position
		add_child(piece)
		tween.tween_property(piece, "modulate:a", 0.0, FADE_SECONDS).set_delay(distance * RING_DELAY)
	var seconds := reach * RING_DELAY + FADE_SECONDS

	light.texture_scale = (reach + 1.0) * 0.4
	tween.tween_property(light, "energy", LIGHT_ENERGY, seconds * 0.3)
	tween.tween_property(light, "energy", 0.0, seconds).set_delay(seconds * 0.3)

	# reach is measured to a corner tile, so this is half the patch's width.
	sparkles.emission_rect_extents = tile * (reach / sqrt(2.0) + 0.5)
	sparkles.emitting = true
	# Sparkles outlive the tiles, so wait for whichever finishes last.
	await get_tree().create_timer(maxf(seconds * 1.3, sparkles.lifetime), false).timeout
	queue_free()
