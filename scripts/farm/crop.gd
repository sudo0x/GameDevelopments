class_name Crop
extends Node2D
## One planted crop. The origin is at the crop's base, for Y-sorting.
## Uses the stages texture from its CropData, or a simple drawn placeholder until that art exists.

const STAGES := 4
const STEM_COLOR := Color(0.36, 0.55, 0.3)
## How high the need icon floats at each stage, so it sits just above the plant.
const NEED_HEIGHTS: Array[float] = [-14.0, -22.0, -30.0, -40.0]
const NEED_BOB_SPEED := 3.0
const BLIGHT_COLOR := Color(0.55, 0.35, 0.7)
## A guarding crop's glow breathes between these, this fast. It's stronger once ripe.
const GLOW_LOW := 0.5
const GLOW_HIGH := 0.85
const RIPE_GLOW_LOW := 0.75
const RIPE_GLOW_HIGH := 1.2
const GLOW_SPEED := 2.4
const GLOW_HEIGHT := -14.0
const GLOW_SIZE := 96
const TILE_SIZE := 32.0

var data: CropData
## 0 = seed, 1 = sprout, 2 = growing, 3 = ripe.
var stage := 0:
	set(value):
		stage = clampi(value, 0, STAGES - 1)
		_update_look()
## Watered days so far. The crop is ripe when this reaches data.days_to_grow.
var days_grown := 0

## The curse reached it: it stops growing, and can only be harvested for a shard.
var blighted := false:
	set(value):
		blighted = value
		_update_look()

## The small icon above the crop for what it needs, or null when it needs nothing.
var need_icon: Texture2D
var _need_sprite := Sprite2D.new()
var _bob_time := 0.0
var _glow: PointLight2D
var _motes: CPUParticles2D
var _ripe_time := 0.0
## How many tiles out this crop guards right now. Its light shows that, instead of a marker.
var _guard_reach := 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_child(_need_sprite)
	_update_look()
	_update_need()


func _process(delta: float) -> void:
	_bob_time += delta
	_need_sprite.offset.y = roundf(sin(_bob_time * NEED_BOB_SPEED))
	_ripe_time += delta
	if _glow and _glow.visible:
		var breath := 0.5 + 0.5 * sin(_ripe_time * GLOW_SPEED)
		var ripe := _shows_ripe_life()
		_glow.energy = lerpf(RIPE_GLOW_LOW if ripe else GLOW_LOW, RIPE_GLOW_HIGH if ripe else GLOW_HIGH, breath)
	if _shows_ripe_life() and data.ripe_animation:
		sprite.frame = int(_ripe_time * data.ripe_fps) % data.ripe_frames


## Shows what the crop needs (Farm decides). Crops loading from a save aren't ready yet.
func show_need(icon: Texture2D) -> void:
	need_icon = icon
	if is_node_ready():
		_update_need()


## Sets how far the crop guards now (Farm decides), so its glow can match.
func show_guard(reach: int) -> void:
	_guard_reach = reach
	if is_node_ready():
		_update_ripe_glow()
		_update_need()


func _update_need() -> void:
	_need_sprite.texture = need_icon
	_need_sprite.visible = need_icon != null
	_need_sprite.position.y = NEED_HEIGHTS[stage]
	set_process(need_icon != null or _shows_ripe_life() or _guard_reach > 0)


## Ripe crops with art or a glow keep moving. Blight takes that away.
func _shows_ripe_life() -> bool:
	return is_ripe() and not blighted and data != null and (data.ripe_glow.a > 0.0 or data.ripe_animation != null)


func is_ripe() -> bool:
	return stage == STAGES - 1


func can_harvest() -> bool:
	return is_ripe() or blighted


func grow_one_day() -> void:
	if not is_ripe() and not blighted:
		set_days_grown(days_grown + 1)


func set_days_grown(days: int) -> void:
	days_grown = days
	stage = _stage_for(days)


## A sprout shows after the first watered night, so even slow crops look alive. The last
## stage is kept for the day the crop is ready.
func _stage_for(days: int) -> int:
	if days <= 0:
		return 0
	if days >= data.days_to_grow:
		return STAGES - 1
	@warning_ignore("integer_division")
	return 1 + (days - 1) * (STAGES - 2) / (data.days_to_grow - 1)


func _update_look() -> void:
	if not is_node_ready():
		return
	sprite.modulate = BLIGHT_COLOR if blighted else Color.WHITE
	if data and data.stages_texture:
		var animated := _shows_ripe_life() and data.ripe_animation != null
		sprite.texture = data.ripe_animation if animated else data.stages_texture
		sprite.hframes = data.ripe_frames if animated else STAGES
		sprite.frame = 0 if animated else stage
		# Frames may be taller than a tile (carrot leaves); keep the bottom at the crop's base.
		sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0)
		sprite.show()
	else:
		sprite.hide()
	_update_ripe_glow()
	_update_need()
	queue_redraw()


func _update_ripe_glow() -> void:
	var glowing := data != null and data.ripe_glow.a > 0.0 and not blighted and _guard_reach > 0
	if glowing and not _glow:
		_add_ripe_glow()
	if _glow:
		_glow.visible = glowing
		# The light reaches about as far as the guard, measured from the plant.
		_glow.texture_scale = (_guard_reach + 1.0) * TILE_SIZE / (GLOW_SIZE / 2.0)
		_motes.emitting = glowing and _shows_ripe_life()


func _add_ripe_glow() -> void:
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	var soft := GradientTexture2D.new()
	soft.gradient = fade
	soft.fill = GradientTexture2D.FILL_RADIAL
	soft.fill_from = Vector2(0.5, 0.5)
	soft.fill_to = Vector2(1.0, 0.5)
	soft.width = GLOW_SIZE
	soft.height = GLOW_SIZE
	_glow = PointLight2D.new()
	_glow.texture = soft
	_glow.color = data.ripe_glow
	_glow.energy = GLOW_LOW
	_glow.position.y = GLOW_HEIGHT
	add_child(_glow)
	_motes = CPUParticles2D.new()
	_motes.amount = 6
	_motes.lifetime = 1.6
	_motes.position.y = GLOW_HEIGHT
	_motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_motes.emission_rect_extents = Vector2(9, 8)
	_motes.direction = Vector2.UP
	_motes.spread = 15.0
	_motes.gravity = Vector2.ZERO
	_motes.initial_velocity_min = 5.0
	_motes.initial_velocity_max = 11.0
	_motes.color = data.ripe_glow
	add_child(_motes)


func _draw() -> void:
	if data == null or data.stages_texture:
		return
	match stage:
		0:
			draw_circle(Vector2(0, -3), 2.0, Color(0.25, 0.18, 0.12))
		1:
			draw_line(Vector2(0, -2), Vector2(0, -8), STEM_COLOR, 2.0)
			draw_circle(Vector2(-2, -8), 2.0, STEM_COLOR)
			draw_circle(Vector2(2, -9), 2.0, STEM_COLOR)
		2:
			draw_line(Vector2(0, -2), Vector2(0, -14), STEM_COLOR, 2.0)
			draw_circle(Vector2(-3, -12), 3.0, STEM_COLOR)
			draw_circle(Vector2(3, -14), 3.0, STEM_COLOR)
		3:
			draw_line(Vector2(0, -6), Vector2(0, -18), STEM_COLOR, 2.0)
			draw_circle(Vector2(-3, -17), 3.0, STEM_COLOR)
			draw_circle(Vector2(3, -18), 3.0, STEM_COLOR)
			draw_circle(Vector2(0, -5), 5.0, data.color)
