class_name Player
extends CharacterBody2D
## The farmer. Walks in 8 directions, shows the closest of the 4 facing poses,
## and holds the selected tool and seed.

signal tool_changed
signal tool_used(tool: Tool)
## The Action button or key was pressed. Farm works out what it means.
signal action_pressed
## The phone's Heal button was pressed. Farm works out what it means.
signal heal_pressed
## The phone's Seed button was pressed. The HUD asks which seed.
signal seed_menu_pressed
## Storage controls: farming or combat mode changed.
signal mode_changed

## Frame order in assets/player/player_idle.png.
## To add diagonal poses later, add frames to the sheet and extend this enum and _facing_for().
enum Facing { DOWN, UP, LEFT, RIGHT }
## Keys 1–7 select these, in this order.
enum Tool { HOE, WATERING_CAN, SEEDS, HAND, HOLY_WATER, BUILD, SWORD }
## Storage controls: the switch button's modes, in the order a tap steps through them.
enum Mode { FARM, COMBAT, BUILD }
const MODE_NAMES := ["Farm", "Combat", "Build"]

const TOOL_NAMES := ["Hoe", "Watering can", "Seeds", "Hand", "Holy water", "Build", "Sword"]
## In the same order as Facing.
const FACING_DIRECTIONS: Array[Vector2] = [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]
## The facing is kept while the walking direction is within 60° of it (cos 60° = 0.5).
const STICKY_FACING := 0.5
## After being hit, nothing can hurt the player for this long.
const SAFE_SECONDS := 1.0
const KNOCKBACK_SPEED := 200.0
## How quickly a knockback dies away, in speed per second.
const KNOCKBACK_FADE := 900.0
## The Action button only uses objects inside this circle, this far in front of the player,
## so a workbench beside or behind them doesn't get in the way of farming.
const FACED_RADIUS := 10.0
const FACED_DISTANCE := 14.0
const BOW_SCENE := preload("res://scenes/player/bow.tscn")
## Thrown pebbles fly like arrows, with their own picture and numbers.
const PEBBLE_SCENE := preload("res://scenes/player/arrow.tscn")

@export var speed: float = 90.0
## Walk animations: 4 frames each (step, pass, step, pass). Side art faces left; right is mirrored.
## A direction without walk art falls back to the idle pose with a small bob.
@export var walk_down: Texture2D
@export var walk_up: Texture2D
@export var walk_side: Texture2D
@export var walk_fps: float = 8.0
@export var bob_height: float = 2.0
@export var steps_per_second: float = 4.0

var facing: Facing = Facing.DOWN
## Last movement direction (8-way).
var look_direction: Vector2 = Vector2.DOWN
var tool: Tool = Tool.HOE
## Index into Inventory.CROPS of the seed planted with the Seeds tool.
var seed_index := 0
## Whether the Holy water tool uses the strong kind.
var strong_water := false
## Index into Inventory.BUILDINGS of the building placed with the Build tool.
var building_index := 0
## Storage controls: what the big button does. Not saved: every morning starts in Farm mode.
var mode := Mode.FARM

var _walk_time: float = 0.0
var _safe_left := 0.0
## Seconds until the next throw.
var _throw_wait := 0.0
var _knockback := Vector2.ZERO
var _faced_query := PhysicsShapeQueryParameters2D.new()

@onready var sprite: Sprite2D = $Sprite2D
@onready var reach: Area2D = $Reach
@onready var sword: Sword = $Sword
## Added in code, so the player scene stays as it is.
var bow: Bow
@onready var _idle_texture: Texture2D = sprite.texture
## Where the player wakes after fainting.
@onready var _home_position: Vector2 = global_position


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = FACED_RADIUS
	_faced_query.shape = circle
	_faced_query.collide_with_areas = true
	_faced_query.collide_with_bodies = false
	bow = BOW_SCENE.instantiate()
	add_child(bow)
	# Every morning starts in Farm mode, the most common job.
	Progress.day_started.connect(func() -> void:
		if GameState.carry_mode and Inventory.combat_pick != 0:
			Inventory.pick_combat(0)
		if GameState.carry_mode and mode != Mode.FARM:
			set_mode(Mode.FARM))
	# Placing the last lantern moves Build mode on to the next building in the set.
	Inventory.inventory_changed.connect(func() -> void:
		if in_mode(Mode.BUILD):
			pick_building())


func _physics_process(delta: float) -> void:
	_throw_wait = maxf(_throw_wait - delta, 0.0)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * speed + _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, KNOCKBACK_FADE * delta)
	move_and_slide()
	_update_safe_time(delta)

	if input != Vector2.ZERO:
		look_direction = input.normalized()
		facing = _facing_for(input)
		_walk_time += delta
	else:
		_walk_time = 0.0
	_update_sprite(input != Vector2.ZERO)


## Blinks while the player can't be hurt, so they can see they're safe for a moment.
func _update_safe_time(delta: float) -> void:
	_safe_left = maxf(_safe_left - delta, 0.0)
	var blink_off := _safe_left > 0.0 and int(_safe_left * 12.0) % 2 == 0
	sprite.modulate.a = 0.35 if blink_off else 1.0


func _update_sprite(moving: bool) -> void:
	var walk := _walk_texture_for(facing) if moving else null
	if walk:
		sprite.texture = walk
		sprite.frame = int(_walk_time * walk_fps) % sprite.hframes
		sprite.flip_h = facing == Facing.RIGHT
		sprite.position.y = 0.0
	else:
		sprite.texture = _idle_texture
		sprite.frame = facing
		sprite.flip_h = false
		sprite.position.y = -roundf(absf(sin(_walk_time * PI * steps_per_second)) * bob_height)


func _walk_texture_for(dir: Facing) -> Texture2D:
	match dir:
		Facing.DOWN:
			return walk_down
		Facing.UP:
			return walk_up
	return walk_side


func _unhandled_input(event: InputEvent) -> void:
	if GameState.carry_mode:
		_carry_input(event)
		return
	for i in Tool.size():
		if event.is_action_pressed("tool_%d" % (i + 1)):
			tool = i as Tool
			tool_changed.emit()
	if event.is_action_pressed("seed_next"):
		_change_selection(1)
	elif event.is_action_pressed("seed_prev"):
		_change_selection(-1)
	if event.is_action_pressed("use_tool"):
		if tool == Tool.SWORD and Inventory.has_sword:
			sword.swing(FACING_DIRECTIONS[facing])
		tool_used.emit(tool)
	if event.is_action_pressed("action"):
		action_pressed.emit()
	if event.is_action_pressed("heal"):
		heal_pressed.emit()
	if event.is_action_pressed("seed_menu"):
		seed_menu_pressed.emit()
	if event.is_action_pressed("build_mode"):
		stop_building()
	if event.is_action_pressed("interact"):
		_interact()


## Storage controls (docs/28_...): no tools to pick. The big button farms, fights or builds with
## what the bag page set. C (or tapping the mode button) goes to the next mode, and keys 1-3
## jump to one. The phone's mode button also opens a wheel when held (TouchControls).
func _carry_input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		action_pressed.emit()
	if event.is_action_pressed("switch_mode"):
		next_mode()
	# Q and E pick the combat button on computers, like tapping a, b or c.
	if mode == Mode.COMBAT and (event.is_action_pressed("seed_next") or event.is_action_pressed("seed_prev")):
		var step := 1 if event.is_action_pressed("seed_next") else -1
		Inventory.pick_combat(posmod(Inventory.combat_pick + step, Inventory.COMBAT_BUTTONS))
	# V, or the build tool button: Place, Move or Pick up.
	if event.is_action_pressed("build_tool") and mode == Mode.BUILD:
		Inventory.next_build_tool()
	for i in Mode.size():
		if event.is_action_pressed("tool_%d" % (i + 1)):
			set_mode(i as Mode)
	if event.is_action_pressed("interact"):
		_interact()


## Farm, then Combat, so a weapon is one tap away while farming.
func next_mode() -> void:
	set_mode(posmod(mode + 1, Mode.size()) as Mode)


func set_mode(value: Mode) -> void:
	mode = value
	# Build mode uses the Build tool, so the preview, cursor and placing work as before.
	tool = Tool.BUILD if mode == Mode.BUILD else Tool.HOE
	pick_building()
	mode_changed.emit()
	tool_changed.emit()


## Build mode places the first building in the build set that's carried.
func pick_building() -> void:
	var ready := Inventory.ready_now(Inventory.build_set)
	if not ready.is_empty():
		building_index = Inventory.BUILDINGS.find(Inventory.building_by_id(StringName(String(ready[0]).substr(6))))


func in_mode(value: Mode) -> bool:
	return GameState.carry_mode and mode == value


## Called by creatures on contact. Does nothing during the short safe time after a hit,
## or while the day is changing.
func hurt(amount: int, direction: Vector2) -> void:
	if _safe_left > 0.0 or Progress.day_changing:
		return
	_safe_left = SAFE_SECONDS
	_knockback = direction * KNOCKBACK_SPEED
	Audio.play(&"hurt")
	Progress.take_damage(amount)


## Sends the player home. Physics interpolation is reset so they jump there instead of sliding.
func return_home() -> void:
	global_position = _home_position
	reset_physics_interpolation()


func selected_seed() -> CropData:
	return Inventory.CROPS[seed_index]


## Starts Build mode on phones, with this entry of Inventory.BUILDINGS in hand.
func start_building(index: int) -> void:
	building_index = index
	tool = Tool.BUILD
	tool_changed.emit()


func stop_building() -> void:
	tool = Tool.HOE
	tool_changed.emit()


func select_seed(index: int) -> void:
	seed_index = index
	tool_changed.emit()


func selected_building() -> BuildingData:
	return Inventory.BUILDINGS[building_index]


## Q and E pick a building, or a kind of holy water, and a seed the rest of the time.
func _change_selection(step: int) -> void:
	if tool == Tool.BUILD:
		for i in Inventory.BUILDINGS.size():
			building_index = posmod(building_index + step, Inventory.BUILDINGS.size())
			var building := Inventory.BUILDINGS[building_index]
			if not building.starting_only or Inventory.building_count(building) > 0:
				break
	elif tool == Tool.HOLY_WATER:
		strong_water = not strong_water
	else:
		seed_index = posmod(seed_index + step, Inventory.CROPS.size())
	tool_changed.emit()


## Turns to a point and swings straight at it, because a creature can come from any side.
func swing_at(point: Vector2, weapon: StringName = &"sword") -> bool:
	return sword.swing(_turn_to(point), weapon)


## Turns toward a point and throws a pebble at it with the sling or by hand, spending a carried
## stone. Returns false with no stone, or while the last throw is still cooling down.
func throw_at(point: Vector2, weapon: StringName) -> bool:
	if _throw_wait > 0.0 or not Inventory.use_stone():
		return false
	var stats: Dictionary = BasicWeapons.STATS[weapon]
	_throw_wait = stats["cooldown"]
	var direction := _turn_to(point)
	Audio.play(&"swing")
	var pebble: Arrow = PEBBLE_SCENE.instantiate()
	pebble.direction = direction
	pebble.speed = stats["speed"]
	pebble.reach = stats["range"]
	pebble.texture = BasicWeapons.PEBBLE
	get_parent().add_child(pebble)
	pebble.global_position = bow.global_position + direction * Bow.HAND
	return true


## Faces the closest of the four ways toward a point, and returns the exact direction.
func _turn_to(point: Vector2) -> Vector2:
	var direction := global_position.direction_to(point)
	if direction == Vector2.ZERO:
		direction = FACING_DIRECTIONS[facing]
	if absf(direction.x) >= absf(direction.y):
		facing = Facing.RIGHT if direction.x > 0.0 else Facing.LEFT
	else:
		facing = Facing.DOWN if direction.y > 0.0 else Facing.UP
	return direction


## Turns toward a point and shoots an arrow at it. Returns false with no arrows, or mid-shot.
func shoot_at(point: Vector2) -> bool:
	var direction := global_position.direction_to(point)
	if direction == Vector2.ZERO:
		direction = FACING_DIRECTIONS[facing]
	if absf(direction.x) >= absf(direction.y):
		facing = Facing.RIGHT if direction.x > 0.0 else Facing.LEFT
	else:
		facing = Facing.DOWN if direction.y > 0.0 else Facing.UP
	return bow.shoot(direction)


## What the Action button does with an object. An object with action_interact() can treat
## Action differently from F, like the door, which asks first.
func use_nearby() -> void:
	var target := action_target()
	if not target:
		return
	if target.has_method("action_interact"):
		target.action_interact(self)
	else:
		target.interact(self)


## Interacts with the first nearby area that has an interact() method (door, shipping box, shop...).
func _interact() -> void:
	var target := interact_target()
	if target:
		target.interact(self)


## The first nearby area with an interact() method, or null. F uses this.
func interact_target() -> Area2D:
	for area in reach.get_overlapping_areas():
		if area.has_method("interact"):
			return area
	return null


## What the Action button would use: a nearby object the player faces, if using it would do
## something. It's stricter than F, because Action also farms, and a tap beside the workbench
## usually means the field.
func action_target() -> Area2D:
	var faced := _faced_areas()
	for area in reach.get_overlapping_areas():
		if not area.has_method("interact") or not faced.has(area):
			continue
		if area.has_method("can_interact") and not area.can_interact():
			continue
		return area
	return null


func _faced_areas() -> Array[Object]:
	_faced_query.transform = Transform2D(0.0, reach.global_position + FACING_DIRECTIONS[facing] * FACED_DISTANCE)
	var areas: Array[Object] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(_faced_query):
		areas.append(hit["collider"])
	return areas


## Sticky facing: keeps the current pose while it still points the way you're walking, so a
## diagonal doesn't turn you away from what you were facing. Otherwise the closest pose wins,
## and exact diagonals use the side pose (like most top-down games).
func _facing_for(dir: Vector2) -> Facing:
	if FACING_DIRECTIONS[facing].dot(dir.normalized()) > STICKY_FACING:
		return facing
	if absf(dir.x) >= absf(dir.y):
		return Facing.RIGHT if dir.x > 0.0 else Facing.LEFT
	return Facing.DOWN if dir.y > 0.0 else Facing.UP
