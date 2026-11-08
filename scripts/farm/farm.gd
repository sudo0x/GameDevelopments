class_name Farm
extends Node2D
## The farm grid: ground and soil tiles, planted crops and the tile the player is targeting.
## Healing cursed land lives in its child node, Healing.

## What the targeted crop needs, or empty text when the player isn't facing one.
signal target_status_changed(text: String)
## What the Action button would do has changed, so its icon should too.
signal action_changed(action: Action)
## What the Heal button would do has changed.
signal heal_changed(heal: Heal)
## The player owns both kinds of holy water, so the HUD should ask which.
signal water_choice_needed
## The player chose a ripe ward plant, so the HUD should ask before bursting it.
signal burst_asked(cell: Vector2i)
## Move: a building was lifted or put down.
signal lift_changed

## Tile source ids in data/tilesets/ground_tileset.tres.
enum Source { GRASS, CURSED, SOIL_DRY, SOIL_WET }
## What the Action button would do, in the order smart_action() checks them.
enum Action { NONE, SWING, INTERACT, HARVEST, WATER, PLANT, GATHER, TILL, PLACE, PICK_UP, HEAL, SHOOT, MOVE, PUT_DOWN }
## What the Heal button would do. The hoe's free daily uses come before holy water.
enum Heal { NONE, PURIFY, HOLY_WATER }

## Each ground texture is 128×128, a 4×4 block of 32×32 tiles.
const TEXTURE_TILES := 4

const FACING_OFFSETS := {
	Player.Facing.DOWN: Vector2i.DOWN,
	Player.Facing.UP: Vector2i.UP,
	Player.Facing.LEFT: Vector2i.LEFT,
	Player.Facing.RIGHT: Vector2i.RIGHT,
}

const CROP_SCENE := preload("res://scenes/farm/crop.tscn")
const WATER_ICON := preload("res://assets/ui/need_water.png")

## Where a building's base sits, measured from the center of its tile.
const BUILDING_BASE := Vector2(0, 12)

## Tools that make something where you aim (soil, a building) never guess another tile.
const EXACT_TOOLS: Array[Player.Tool] = [Player.Tool.HOE, Player.Tool.BUILD]
## Action can't do these, so on phones the cursor shows the tool's tile while one is selected.
const USE_BUTTON_TOOLS: Array[Player.Tool] = [Player.Tool.BUILD]

## The tool behind each Action that uses one. Action only chooses: the tools do the work.
const ACTION_TOOLS := {
	Action.SWING: Player.Tool.SWORD,
	Action.HARVEST: Player.Tool.HAND,
	Action.WATER: Player.Tool.WATERING_CAN,
	Action.PLANT: Player.Tool.SEEDS,
	Action.GATHER: Player.Tool.HAND,
	Action.TILL: Player.Tool.HOE,
	Action.PLACE: Player.Tool.BUILD,
	Action.PICK_UP: Player.Tool.BUILD,
	Action.MOVE: Player.Tool.BUILD,
	Action.PUT_DOWN: Player.Tool.BUILD,
}

## A lifted building fades until it's put down.
const LIFTED_COLOR := Color(1, 1, 1, 0.4)

@export var player_path: NodePath
## Y-sorted node that planted crops are added to, so the player can walk behind them.
@export var crops_parent_path: NodePath

var target_cell := Vector2i.ZERO
## The tile the Action button would work on.
var action_cell := Vector2i.ZERO
## Planted crops by cell.
var crops: Dictionary[Vector2i, Crop] = {}
var _target_status := ""
var _shown_action := Action.NONE
var _shown_heal := Heal.NONE
## Seconds left before the Action button can use objects again.
var _object_pause := 0.0
## The tile the cursor is on, and the one the status text describes.
var _shown_cell := Vector2i.ZERO
## Phones: press and hold a building to move it.
var mover := BuildingMover.new()
## Phones: tap a ripe ward plant to burst it.
var ward_tap := WardTap.new()
## Nights each tilled cell has spent with no crop; at soil_idle_nights it turns back into grass.
var soil_idle: Dictionary[Vector2i, int] = {}
## Move: the cell of the building lifted and not yet put down, or Builder.NO_CELL.
var lifted := Builder.NO_CELL
## Reused to check whether a solid object stands on a cell.
var _cell_query := PhysicsShapeQueryParameters2D.new()
## The same, but it also sees interact areas and the player, to keep them clear of buildings.
var _build_query := PhysicsShapeQueryParameters2D.new()

@onready var ground: TileMapLayer = $Ground
@onready var soil: TileMapLayer = $Soil
@onready var soil_edges: SoilEdges = $SoilEdges
@onready var wet_edges: WetEdges = $WetEdges
@onready var healing: Healing = $Healing
@onready var gathering: Gathering = $Gathering
@onready var build_preview: BuildPreview = $BuildPreview
@onready var builder: Builder = $Builder
@onready var spawner: CreatureSpawner = $Spawner
@onready var highlight: TileHighlight = $Highlight
@onready var player: Player = get_node(player_path)
@onready var crops_parent: Node2D = get_node(crops_parent_path)


func _ready() -> void:
	# First, because the player, HUD and storage chest all read it as they start.
	GameState.apply_controls_setting()
	Inventory.give_starter_kit()
	var shape := RectangleShape2D.new()
	# A little smaller than a tile, so a neighbor's collision doesn't count.
	shape.size = Vector2(ground.tile_set.tile_size) - Vector2(4, 4)
	_cell_query.shape = shape
	_cell_query.exclude = [player.get_rid()]
	# Layer 1 only, so a creature passing by doesn't block farming or building.
	_cell_query.collision_mask = 1
	_build_query.collision_mask = 1
	_build_query.shape = shape
	_build_query.collide_with_areas = true
	# Without this, the player's own areas would count as something in the way.
	# get_node, because Farm starts before Player, so player.reach isn't set yet.
	_build_query.exclude = [player.get_node("Reach").get_rid(), player.get_node("Sword/Hitbox").get_rid()]
	player.tool_used.connect(_on_tool_used)
	player.action_pressed.connect(run_action)
	player.heal_pressed.connect(run_heal)
	healing.land_healed.connect(gathering.reveal)
	# Healed land beside a field is new grass, so the field's edge changes.
	healing.land_healed.connect(func(_cells: Array[Vector2i]) -> void: _refresh_soil_edges())
	healing.land_healed.connect(func(_cells: Array[Vector2i]) -> void: healing.refresh_marks(_can_curse_take))
	builder.setup(ground, crops_parent)
	mover.setup(self)
	add_child(mover)
	ward_tap.setup(self)
	add_child(ward_tap)
	spawner.setup(self, crops_parent, player)
	Progress.day_ended.connect(spawner.clear)
	Progress.day_started.connect(spawner.spawn_for_today)
	Progress.day_ended.connect(_on_day_ended)
	Progress.day_started.connect(_on_day_started)
	_limit_camera()
	_restore(SaveGame.farm_state)
	healing.mark_tonight(_can_curse_take)
	spawner.spawn_for_today()
	Audio.play_music(&"farm")


func _physics_process(delta: float) -> void:
	_object_pause = maxf(_object_pause - delta, 0.0)
	target_cell = smart_target_for(player)
	var action := Action.NONE
	# Only the phone's buttons show these, so computers skip the work.
	if GameState.touch_mode or GameState.carry_mode:
		action_cell = action_target_for(player)
		action = smart_action(action_cell)
		_tell_buttons(action)
	var by_action: bool = GameState.carry_mode or (GameState.touch_mode and player.tool not in USE_BUTTON_TOOLS)
	_shown_cell = action_cell if by_action else target_cell
	var tile := Vector2(ground.tile_set.tile_size)
	var rect := Rect2(ground.map_to_local(_shown_cell) - tile / 2.0, tile)
	if GameState.carry_mode and action == Action.HEAL:
		rect = rect.grow(tile.x * healing.radius_for(_water_for(action_cell) == &"strong_holy_water"))
	elif player.tool == Player.Tool.HOLY_WATER and not GameState.carry_mode:
		rect = rect.grow(tile.x * healing.radius_for(player.strong_water))
	# The Action button's seed picture follows the seed it would plant.
	if GameState.carry_mode and action == Action.PLANT:
		player.seed_index = Inventory.CROPS.find(_seed_for(action_cell))
	# Placing a guard shows what it would protect. In play, light shows that instead.
	var guard := _placing_guard_radius()
	if guard > 0:
		highlight.show_area(rect.grow(tile.x * guard), _can_move_lifted(_shown_cell) if lifted != Builder.NO_CELL else _can_place(_shown_cell))
		highlight.visible = true
	elif by_action:
		highlight.show_cell(rect, action != Action.NONE)
		# Swinging and using an object don't happen on the tile, so don't point at it.
		highlight.visible = action not in [Action.SWING, Action.SHOOT, Action.INTERACT]
	else:
		highlight.show_cell(rect, can_use(player.tool, target_cell))
		# The sword works on whatever is in front, not on a tile.
		highlight.visible = player.tool != Player.Tool.SWORD
	_update_build_preview()
	_update_target_status()


func _tell_buttons(action: Action) -> void:
	if action != _shown_action:
		_shown_action = action
		action_changed.emit(action)
	var heal := smart_heal(heal_target_for(player))
	if heal != _shown_heal:
		_shown_heal = heal
		heal_changed.emit(heal)


## The tile in front of the player's feet, in the direction they face.
func target_cell_for(p: Player) -> Vector2i:
	var feet_cell := ground.local_to_map(ground.to_local(p.global_position + Vector2(0, -4)))
	return feet_cell + FACING_OFFSETS[p.facing]


## Aim assist: the tile ahead if the tool can use it, or else a tile beside that one
## (the side nearer the player first), so a rock half a tile off doesn't need nudging.
## The cursor always shows the result, so it's never a surprise.
func smart_target_for(p: Player) -> Vector2i:
	var ahead := target_cell_for(p)
	if p.tool in EXACT_TOOLS or can_use(p.tool, ahead):
		return ahead
	return _beside(p, ahead, func(cell: Vector2i) -> bool: return can_use(p.tool, cell))


## Aim assist for the Action button. The tile ahead wins if it has any action. Tiles beside it
## can't be tilled, because new soil should only ever appear straight ahead.
func action_target_for(p: Player) -> Vector2i:
	var ahead := target_cell_for(p)
	if GameState.carry_mode:
		if _is_building() or _carry_action(ahead) != Action.NONE:
			return ahead
		# New soil and healing only ever happen straight ahead.
		return _beside(p, ahead, func(cell: Vector2i) -> bool:
			return _carry_action(cell) not in [Action.NONE, Action.TILL, Action.HEAL])
	if _is_building() or _tile_action(ahead) != Action.NONE:
		return ahead
	return _beside(p, ahead, func(cell: Vector2i) -> bool:
		return _tile_action(cell) != Action.NONE and _tile_action(cell) != Action.TILL)


## The first tile beside the one ahead (nearer side first) that passes, or the one ahead.
func _beside(p: Player, ahead: Vector2i, usable: Callable) -> Vector2i:
	var facing: Vector2i = FACING_OFFSETS[p.facing]
	var side := Vector2i(facing.y, facing.x)
	var sides: Array[Vector2i] = [ahead + side, ahead - side]
	var feet := ground.to_local(p.global_position)
	sides.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return feet.distance_squared_to(ground.map_to_local(a)) < feet.distance_squared_to(ground.map_to_local(b)))
	for cell in sides:
		if usable.call(cell):
			return cell
	return ahead


## Any clean grass can be farmed, unless something solid stands on it.
func is_farmable(cell: Vector2i) -> bool:
	return ground.get_cell_source_id(cell) == Source.GRASS and not _has_solid_object(cell) and not in_ward_space(cell)


## Whether this tile must stay clear because a ward plant grows beside it. Nothing marks these
## tiles, so the ground stays calm: ward_space_status() explains when the player faces one.
func in_ward_space(cell: Vector2i) -> bool:
	for center in crops:
		if center != cell and tiles_apart(cell, center) <= crops[center].data.space_radius:
			return true
	return false


## Whether a crop that needs space has it here: no crops or buildings in it, and no overlap
## with another's.
func _has_room_for(crop: CropData, cell: Vector2i) -> bool:
	if crop.space_radius <= 0:
		return true
	for other in crops:
		if other != cell and tiles_apart(cell, other) <= crop.space_radius + crops[other].data.space_radius:
			return false
	for other in builder.placed:
		if tiles_apart(cell, other) <= crop.space_radius:
			return false
	return true


## How far apart two cells are, counting a diagonal step as one. Everything with a square
## area uses this: guards, spacing and bursts.
static func tiles_apart(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## How far the building about to be placed would guard. 0 when not placing one.
func _placing_guard_radius() -> int:
	if lifted != Builder.NO_CELL:
		return builder.placed[lifted]["data"].guard_radius if builder.placed.has(lifted) else 0
	if GameState.carry_mode and Inventory.build_tool != &"place":
		return 0
	if player.tool != Player.Tool.BUILD or builder.placed.has(_shown_cell) or _nothing_to_build():
		return 0
	return player.selected_building().guard_radius


## How far a ward plant on this cell reaches right now. A seed guards only its own tile, so
## planting can't save tonight's marks: guarding takes planning ahead. A ripe one has finished
## growing, so it needs no water.
func ward_reach(cell: Vector2i) -> int:
	var crop := crops[cell]
	if crop.data.ward_radius <= 0 or crop.stage == 0:
		return 0
	if crop.is_ripe():
		return crop.data.ward_ripe_radius
	return crop.data.ward_radius if is_watered(cell) else crop.data.ward_dry_radius


func is_tilled(cell: Vector2i) -> bool:
	return soil.get_cell_source_id(cell) != -1


func is_watered(cell: Vector2i) -> bool:
	return soil.get_cell_source_id(cell) == Source.SOIL_WET


## Buildings need clean grass with nothing on it, and must keep doors, shops and the player clear.
func can_build(cell: Vector2i) -> bool:
	if ground.get_cell_source_id(cell) != Source.GRASS or is_tilled(cell) or gathering.spots.has(cell) or in_ward_space(cell):
		return false
	_build_query.transform = _cell_transform(cell)
	return get_world_2d().direct_space_state.intersect_shape(_build_query, 1).is_empty()


## Whether the tool would do something on this cell (drives the highlight color).
func can_use(tool: Player.Tool, cell: Vector2i) -> bool:
	match tool:
		Player.Tool.HOE:
			# Empty soil can be hoed back into grass.
			if is_tilled(cell):
				return not crops.has(cell)
			return is_farmable(cell) or healing.can_purify(cell)
		Player.Tool.WATERING_CAN:
			return is_tilled(cell) and not is_watered(cell) and Inventory.can_water > 0
		Player.Tool.SEEDS:
			var seed_crop := player.selected_seed()
			return is_tilled(cell) and not crops.has(cell) and Inventory.carried(Inventory.seed_item(seed_crop)) > 0 \
					and not in_ward_space(cell) and _has_room_for(seed_crop, cell)
		Player.Tool.HAND:
			return (crops.has(cell) and crops[cell].can_harvest()) or gathering.can_hit(cell) or builder.placed.has(cell)
		Player.Tool.HOLY_WATER:
			var owned := Inventory.carried(&"strong_holy_water" if player.strong_water else &"holy_water")
			return owned > 0 and not healing.cleansable_cells(cell, player.strong_water).is_empty()
		Player.Tool.BUILD:
			# Phones pick buildings up here. Computers have the Hand tool for that.
			return _can_place(cell) or ((GameState.touch_mode or GameState.carry_mode) and builder.placed.has(cell))
	return false


## What the Action button would do with this cell in front of the player. It changes nothing.
## Holy water, picking up buildings and hoeing soil back are left out on purpose, so they
## can't happen by accident (docs/24_...).
func smart_action(cell: Vector2i) -> Action:
	if GameState.carry_mode:
		return _carry_action(cell)
	if _creature_to_swing_at():
		return Action.SWING
	# While building, a stray tap mustn't till the tile you're about to build on.
	if _is_building():
		return _build_action(cell)
	if _object_pause <= 0.0 and player.action_target():
		return Action.INTERACT
	return _tile_action(cell)


## Does what smart_action() says. The selected tool stays selected.
func run_action() -> void:
	if Progress.day_changing:
		return
	var cell := action_target_for(player)
	var action := smart_action(cell)
	if GameState.carry_mode:
		_run_carry(action, cell)
		return
	match action:
		Action.NONE:
			return
		Action.SWING:
			player.swing_at(_creature_to_swing_at().global_position)
		Action.INTERACT:
			player.use_nearby()
		_:
			_use_tool(ACTION_TOOLS[action], cell)
			_object_pause = GameState.BALANCE.action_object_pause
	# Nothing left to place, so there's nothing left to do here.
	if action == Action.PLACE and Inventory.building_count(player.selected_building()) == 0:
		player.stop_building()


## Storage controls (docs/28_...): what the big button would do. In Farm mode it's smart, like
## the classic Action button, but only with what the farming set holds. In Combat mode it uses
## the combat set's first weapon with something left. In Build mode it picks up the building
## ahead, or places the build set's first. Objects aren't used: they're tapped.
func _carry_action(cell: Vector2i) -> Action:
	match player.mode:
		Player.Mode.COMBAT:
			var using := weapon()
			if using == &"":
				return Action.NONE
			return Action.SHOOT if using == &"bow" or BasicWeapons.throws(using) else Action.SWING
		Player.Mode.BUILD:
			return _build_tool_action(cell)
	return _farm_action(cell)


## The weapon the big button fights with: the picked combat button's, if it can be used now.
## A bow with no arrows can't. Empty when there's none.
func weapon(index: int = -1) -> StringName:
	var item := Inventory.combat_item(Inventory.combat_pick if index < 0 else index)
	if item == &"" or Inventory.carried(item) <= 0:
		return &""
	if item == &"bow" and Inventory.carried(&"arrows") <= 0:
		return &""
	# The sling and throwing stones throw carried stones.
	if BasicWeapons.throws(item) and Inventory.carried(&"mat_stone") <= 0:
		return &""
	return item


## A farm job is switched on, and the tool it needs is carried.
func _can_do(job: StringName, tool_item: StringName = &"") -> bool:
	return Inventory.job_on(job) and (tool_item == &"" or Inventory.carried(tool_item) > 0)


## The classic button's farming order, doing only the farm jobs that are on. Holy water is only
## used on a cursed tile straight ahead, so it's never spent by farming beside the curse.
func _farm_action(cell: Vector2i) -> Action:
	if crops.has(cell):
		# Bursting can't be undone, so farming beside a ward plant must never do it.
		# A ripe crop is left alone with Harvest off: it may be kept for its looks.
		if crops[cell].can_harvest():
			return Action.HARVEST if _can_do(&"harvest") and not _is_ripe_ward(cell) else Action.NONE
		return Action.WATER if _can_do(&"water", &"can") and can_use(Player.Tool.WATERING_CAN, cell) else Action.NONE
	if is_tilled(cell):
		return Action.PLANT if _can_do(&"plant") and _seed_for(cell) else Action.NONE
	if gathering.can_hit(cell):
		return Action.GATHER if _can_do(&"gather") else Action.NONE
	if is_farmable(cell) and _can_do(&"till", &"hoe"):
		return Action.TILL
	if ground.get_cell_source_id(cell) == Source.CURSED and _can_do(&"heal"):
		if Inventory.carried(&"hoe") > 0 and healing.can_purify(cell):
			return Action.TILL
		if _water_for(cell) != &"":
			return Action.HEAL
	return Action.NONE


## The first seed to plant that can grow here. Seeds the player didn't pick are never planted.
func _seed_for(cell: Vector2i) -> CropData:
	if in_ward_space(cell):
		return null
	for item in Inventory.ready_now(Inventory.plant_set):
		var crop := Inventory.crop_by_id(StringName(String(item).substr(5)))
		if _has_room_for(crop, cell):
			return crop
	return null


## The carried holy water that would heal something here: the plain kind first, because the
## strong kind is rarer.
func _water_for(cell: Vector2i) -> StringName:
	for item: StringName in [&"holy_water", &"strong_holy_water"]:
		if Inventory.carried(item) > 0 and not healing.cleansable_cells(cell, item == &"strong_holy_water").is_empty():
			return item
	return &""


func _run_carry(action: Action, cell: Vector2i) -> void:
	match action:
		Action.NONE:
			if player.mode == Player.Mode.COMBAT:
				GameState.notice.emit(_no_weapon_text())
			elif player.mode == Player.Mode.BUILD and Inventory.build_tool == &"place" and Inventory.ready_now(Inventory.build_set).is_empty():
				GameState.notice.emit("Nothing in the build set. Add a building on the Modes page.")
			return
		Action.SWING:
			var creature := _creature_to_swing_at()
			var at := creature.global_position if creature else player.global_position + Player.FACING_DIRECTIONS[player.facing]
			var using := weapon()
			if player.swing_at(at, using) and using == &"torch":
				Inventory.burn_torch()
		Action.SHOOT:
			var using := weapon()
			var reach: float = GameState.BALANCE.bow_range if using == &"bow" else BasicWeapons.STATS[using]["range"]
			var target := spawner.nearest_within(player.global_position, reach)
			var aim := target.global_position if target else player.global_position + Player.FACING_DIRECTIONS[player.facing]
			if using == &"bow":
				player.shoot_at(aim)
			else:
				player.throw_at(aim, using)
		Action.HARVEST, Action.GATHER:
			_use_tool(Player.Tool.HAND, cell)
		Action.WATER:
			_use_tool(Player.Tool.WATERING_CAN, cell)
		Action.TILL:
			_use_tool(Player.Tool.HOE, cell)
		Action.PLANT:
			player.seed_index = Inventory.CROPS.find(_seed_for(cell))
			_use_tool(Player.Tool.SEEDS, cell)
		Action.HEAL:
			player.strong_water = _water_for(cell) == &"strong_holy_water"
			_use_tool(Player.Tool.HOLY_WATER, cell)
		Action.PLACE:
			_use_tool(Player.Tool.BUILD, cell)
		Action.MOVE:
			_lift(cell)
		Action.PUT_DOWN:
			var from := lifted
			drop_lifted()
			if cell != from:
				move_building(from, cell)
		Action.PICK_UP:
			# Moving is picking up, then placing: what was just picked up is placed next.
			var item := Inventory.building_item(builder.placed[cell]["data"])
			# A full bag would send it to storage, where it seems lost: make room first.
			if not Inventory.has_room_for(item):
				GameState.notice.emit("Your bag is full. Put something in storage first.")
				return
			_use_tool(Player.Tool.BUILD, cell)
			if Inventory.carried(item) > 0:
				Inventory.to_front(item)
				player.pick_building()


## Storage controls: Build mode does one thing at a time, picked with the build tool button, so
## the big button is never a guess between placing and picking up.
func _build_tool_action(cell: Vector2i) -> Action:
	match Inventory.build_tool:
		&"move":
			if lifted != Builder.NO_CELL:
				# Putting it down where it was just cancels the move.
				return Action.PUT_DOWN if cell == lifted or can_move(lifted, cell) else Action.NONE
			return Action.MOVE if builder.placed.has(cell) else Action.NONE
		&"pick_up":
			return Action.PICK_UP if builder.placed.has(cell) else Action.NONE
	if builder.placed.has(cell) or Inventory.ready_now(Inventory.build_set).is_empty():
		return Action.NONE
	return Action.PLACE if _can_place(cell) else Action.NONE


## Move: lifts a building. It stays where it is, faded, until it's put down, so leaving Build
## mode, changing tool or the day ending can't lose it.
func _lift(cell: Vector2i) -> void:
	lifted = cell
	lift_changed.emit()
	builder.placed[cell]["node"].modulate = LIFTED_COLOR
	Audio.play(&"pick_up")
	GameState.notice.emit("Lifted: %s. Walk to a free spot and %s." % [builder.placed[cell]["data"].display_name, GameState.controls("press R", "tap the big button")])


## Whether the lifted building could be put down here; its own spot always can.
func _can_move_lifted(cell: Vector2i) -> bool:
	return cell == lifted or can_move(lifted, cell)


## Puts a lifted building back down where it was.
func drop_lifted() -> void:
	if lifted != Builder.NO_CELL and builder.placed.has(lifted):
		builder.placed[lifted]["node"].modulate = Color.WHITE
	if lifted != Builder.NO_CELL:
		lifted = Builder.NO_CELL
		lift_changed.emit()


## Anything that ends a move before it's put down cancels it.
func _keep_lifted() -> void:
	if lifted == Builder.NO_CELL:
		return
	if not builder.placed.has(lifted) or not player.in_mode(Player.Mode.BUILD) or Inventory.build_tool != &"move":
		drop_lifted()


## Storage controls: Build mode with an empty build set has nothing to show.
func _nothing_to_build() -> bool:
	return GameState.carry_mode and Inventory.ready_now(Inventory.build_set).is_empty()


## Build mode: on a phone, or with storage controls. Computers use the Build tool with Space instead.
func _is_building() -> bool:
	if GameState.carry_mode:
		return player.mode == Player.Mode.BUILD
	return GameState.touch_mode and player.tool == Player.Tool.BUILD


func _build_action(cell: Vector2i) -> Action:
	if builder.placed.has(cell):
		return Action.PICK_UP
	return Action.PLACE if _can_place(cell) else Action.NONE


func _creature_to_swing_at() -> Creature:
	if not Inventory.has_sword and not GameState.carry_mode:
		return null
	return spawner.nearest_within(player.global_position, GameState.BALANCE.action_swing_distance)


func _tile_action(cell: Vector2i) -> Action:
	if crops.has(cell):
		# Bursting can't be undone, so farming beside a ward plant must never do it.
		if crops[cell].can_harvest():
			return Action.NONE if _is_ripe_ward(cell) else Action.HARVEST
		return Action.WATER if can_use(Player.Tool.WATERING_CAN, cell) else Action.NONE
	if is_tilled(cell):
		return Action.PLANT if can_use(Player.Tool.SEEDS, cell) else Action.NONE
	if gathering.can_hit(cell):
		return Action.GATHER
	return Action.TILL if is_farmable(cell) else Action.NONE


## A lantern's or ward's cover moves with it, so tonight's marks can change.
func move_building(from: Vector2i, to: Vector2i) -> void:
	builder.move(from, to)
	Audio.play(&"place")
	healing.refresh_marks(_can_curse_take)


func _can_place(cell: Vector2i) -> bool:
	var building := player.selected_building()
	return Inventory.carried(Inventory.building_item(building)) > 0 and can_build(cell) and builder.has_room(cell, building)


## Whether a placed building can move to this cell. Its own spot doesn't count against it.
func can_move(from: Vector2i, to: Vector2i) -> bool:
	return can_build(to) and builder.has_room(to, builder.placed[from]["data"], from)


func _is_ripe_ward(cell: Vector2i) -> bool:
	return crops.has(cell) and crops[cell].data.burst_radius > 0 and crops[cell].is_ripe()


## The ripe ward plant drawn at this world point, or Builder.NO_CELL.
func ripe_ward_at(point: Vector2) -> Vector2i:
	for cell in crops:
		if not _is_ripe_ward(cell):
			continue
		var art: Sprite2D = crops[cell].sprite
		var size := art.texture.get_size() / Vector2(art.hframes, 1)
		if Rect2(crops[cell].global_position - Vector2(size.x / 2.0, size.y), size).has_point(point):
			return cell
	return Builder.NO_CELL


func player_cell() -> Vector2i:
	return ground.local_to_map(ground.to_local(player.global_position + Vector2(0, -4)))


## The player said yes to the question.
func burst(cell: Vector2i) -> void:
	if _is_ripe_ward(cell):
		_use_tool(Player.Tool.HAND, cell)


## What the Heal button would do on this cell. It changes nothing.
func smart_heal(cell: Vector2i) -> Heal:
	if healing.can_purify(cell):
		return Heal.PURIFY
	return Heal.HOLY_WATER if not _waters_for(cell).is_empty() else Heal.NONE


## Which kinds of holy water would heal something here: false is normal, true is strong.
func _waters_for(cell: Vector2i) -> Array[bool]:
	var waters: Array[bool] = []
	if Inventory.carried(&"holy_water") > 0 and not healing.cleansable_cells(cell, false).is_empty():
		waters.append(false)
	if Inventory.carried(&"strong_holy_water") > 0 and not healing.cleansable_cells(cell, true).is_empty():
		waters.append(true)
	return waters


## Aim assist for the Heal button, like the holy water tool's.
func heal_target_for(p: Player) -> Vector2i:
	var ahead := target_cell_for(p)
	if smart_heal(ahead) != Heal.NONE:
		return ahead
	return _beside(p, ahead, func(cell: Vector2i) -> bool: return smart_heal(cell) != Heal.NONE)


## Does what smart_heal() says. Holy water is limited, so with two kinds the player chooses.
func run_heal() -> void:
	if Progress.day_changing:
		return
	var cell := heal_target_for(player)
	match smart_heal(cell):
		Heal.PURIFY:
			_use_tool(Player.Tool.HOE, cell)
		Heal.HOLY_WATER:
			var waters := _waters_for(cell)
			if waters.size() > 1:
				water_choice_needed.emit()
			else:
				heal_with(waters[0])


func heal_with(strong: bool) -> void:
	player.strong_water = strong
	_use_tool(Player.Tool.HOLY_WATER, heal_target_for(player))


func till(cell: Vector2i) -> void:
	soil.set_cell(cell, Source.SOIL_DRY, texture_coords(cell))


## Turns soil back into grass. The caller refreshes the soil edges.
func untill(cell: Vector2i) -> void:
	soil.erase_cell(cell)
	soil_idle.erase(cell)


func water(cell: Vector2i) -> void:
	soil.set_cell(cell, Source.SOIL_WET, texture_coords(cell))


func plant(cell: Vector2i, data: CropData) -> void:
	if not Inventory.use_seed(data):
		return
	_add_crop(cell, data)


## Picks the crop. The soil stays tilled, so the cell can be planted again.
func harvest(cell: Vector2i) -> void:
	var crop: Crop = crops[cell]
	crops.erase(cell)
	crop.queue_free()
	if crop.blighted:
		Inventory.take_blighted_crop()
	elif crop.data.burst_radius > 0:
		var healed := healing.burst(cell, crop.data.burst_radius)
		GameState.notice.emit("The %s burst and healed %s!" % [crop.data.display_name.to_lower(), _tiles_text(healed)])
	else:
		Inventory.add_harvest(crop.data)


func _update_build_preview() -> void:
	# The mover draws the preview while it's dragging.
	if mover.moving:
		return
	_keep_lifted()
	if lifted != Builder.NO_CELL:
		var to := ground.map_to_local(target_cell) + BUILDING_BASE
		build_preview.show_at(builder.placed[lifted]["data"], to, target_cell == lifted or can_move(lifted, target_cell))
		return
	if GameState.carry_mode and Inventory.build_tool != &"place":
		build_preview.hide()
		return
	if player.tool != Player.Tool.BUILD or _nothing_to_build():
		build_preview.hide()
		return
	var at := ground.map_to_local(target_cell) + BUILDING_BASE
	build_preview.show_at(player.selected_building(), at, _can_place(target_cell))


func _update_target_status() -> void:
	var status := spacing_status(_shown_cell)
	if status.is_empty():
		status = ward_space_status(_shown_cell)
	if status.is_empty():
		status = ward_room_status(_shown_cell)
	if status.is_empty():
		status = curse_status(_shown_cell)
	if status.is_empty():
		status = crop_status(_shown_cell)
	if status.is_empty():
		status = soil_status(_shown_cell)
	if status.is_empty():
		status = gathering.status(_shown_cell) + builder.status(_shown_cell)
	if status != _target_status:
		_target_status = status
		target_status_changed.emit(status)


## Tells the player how a crop is doing, because growth is slow and easy to miss.
func crop_status(cell: Vector2i) -> String:
	if not crops.has(cell):
		return ""
	var crop := crops[cell]
	if crop.blighted:
		return "Blighted %s. %s" % [crop.data.display_name.to_lower(), GameState.controls("Press R to clear it for a curse shard.", "Tap the big button for a curse shard.")]
	if crop.is_ripe() and crop.data.burst_radius > 0:
		return "%s is ready! %s" % [crop.data.display_name, GameState.controls("Press 4, then Space to burst it, or leave it to guard.", "Walk up and tap it to burst it, or leave it to guard.")]
	if crop.is_ripe():
		return "%s is ripe! %s" % [crop.data.display_name, GameState.controls("Press R to harvest.", "Tap the big button.")]
	return _growing_status(cell, crop)


## Empty soil quietly turns back into grass, so warn on its last night only.
func soil_status(cell: Vector2i) -> String:
	if not is_tilled(cell) or crops.has(cell):
		return ""
	if GameState.BALANCE.soil_idle_nights - soil_idle.get(cell, 0) > 1:
		return ""
	return "Empty soil: grass returns tonight."


## Says why a building can't go here, since a red preview alone doesn't.
func spacing_status(cell: Vector2i) -> String:
	if player.tool != Player.Tool.BUILD or builder.placed.has(cell):
		return ""
	var building := player.selected_building()
	if builder.has_room(cell, building):
		return ""
	return "%ss must stand %d tiles apart." % [building.display_name, building.min_spacing]


## Says why this tile can't be used. Only shown when it matters, so nothing marks the ground.
func ward_space_status(cell: Vector2i) -> String:
	return "This tile belongs to the wardthorn." if in_ward_space(cell) else ""


## Says why a ward seed can't be planted on this soil, since it's easy to miss.
func ward_room_status(cell: Vector2i) -> String:
	var crop := player.selected_seed()
	if crop.space_radius <= 0 or not is_tilled(cell) or crops.has(cell) or _has_room_for(crop, cell):
		return ""
	return "%s needs the tiles around it clear." % crop.display_name


## How a player learns what the marks mean and what saves a tile.
func curse_status(cell: Vector2i) -> String:
	if not healing.is_at_risk(cell, _can_curse_take):
		return ""
	if crops.has(cell):
		return "The curse will blight this crop tonight. Harvest it, or guard it."
	return "The curse takes this tile tonight. Use a lantern or wardthorn."


func _growing_status(cell: Vector2i, crop: Crop) -> String:
	var progress := "%s: %d of %d days" % [crop.data.display_name, crop.days_grown, crop.data.days_to_grow]
	if crop.data.ward_radius > 0 and crop.stage == 0:
		progress += ". It guards once it sprouts"
	if is_watered(cell):
		return progress + ", watered. Sleep to grow."
	if Inventory.can_water <= 0:
		return progress + ", needs water. Refill at a well."
	return progress + ", needs water."


func _has_solid_object(cell: Vector2i) -> bool:
	_cell_query.transform = _cell_transform(cell)
	return not get_world_2d().direct_space_state.intersect_shape(_cell_query, 1).is_empty()


func _cell_transform(cell: Vector2i) -> Transform2D:
	return Transform2D(0.0, ground.to_global(ground.map_to_local(cell)))


func _add_crop(cell: Vector2i, data: CropData) -> Crop:
	var crop: Crop = CROP_SCENE.instantiate()
	crop.data = data
	crop.position = crops_parent.to_local(ground.to_global(ground.map_to_local(cell))) + Vector2(0, 12)
	crops_parent.add_child(crop)
	crops[cell] = crop
	return crop


## Which 32×32 piece of a 128×128 texture a cell uses, so neighbors line up seamlessly.
static func texture_coords(cell: Vector2i) -> Vector2i:
	return Vector2i(posmod(cell.x, TEXTURE_TILES), posmod(cell.y, TEXTURE_TILES))


func _on_tool_used(tool: Player.Tool) -> void:
	if tool == Player.Tool.HAND and _is_ripe_ward(target_cell):
		burst_asked.emit(target_cell)
		return
	_use_tool(tool, target_cell)


func _use_tool(tool: Player.Tool, cell: Vector2i) -> void:
	if not can_use(tool, cell):
		return
	match tool:
		Player.Tool.HOE:
			if healing.is_cleansable(cell):
				healing.purify(cell)
			else:
				if is_tilled(cell):
					untill(cell)
				else:
					till(cell)
					Progress.record_action("till")
				Audio.play(&"till")
			_refresh_soil_edges()
		Player.Tool.WATERING_CAN:
			water(cell)
			Inventory.use_can_water()
			if Inventory.can_water == 0:
				GameState.notice.emit("The watering can is empty. Refill it at a well.")
			Progress.record_action("water")
			Audio.play(&"water")
			_refresh_soil_edges()
		Player.Tool.SEEDS:
			plant(cell, player.selected_seed())
			Progress.record_action("plant_ward" if player.selected_seed().ward_radius > 0 else "plant")
			Audio.play(&"plant")
		Player.Tool.HAND:
			if crops.has(cell):
				harvest(cell)
				Progress.record_action("harvest")
				Audio.play(&"harvest")
			elif builder.placed.has(cell):
				builder.pick_up(cell)
				Audio.play(&"pick_up")
			else:
				gathering.hit(cell)
				Audio.play(&"gather")
		Player.Tool.HOLY_WATER:
			healing.cleanse(cell, player.strong_water)
			Progress.record_action("heal")
		Player.Tool.BUILD:
			if builder.placed.has(cell):
				builder.pick_up(cell)
				Audio.play(&"pick_up")
			else:
				builder.place(cell, player.selected_building())
				Audio.play(&"place")
	_refresh_crop_needs()
	healing.refresh_marks(_can_curse_take)


## Overnight: watered crops grow one day, empty soil slowly turns back into grass,
## then all soil dries.
func _on_day_ended() -> void:
	for cell in crops:
		if is_watered(cell):
			crops[cell].grow_one_day()
	_age_empty_soil()
	# Before the soil dries, because a wardthorn only guards while it's watered.
	_curse_comes_back()
	for cell in soil.get_used_cells_by_id(Source.SOIL_WET):
		till(cell)
	gathering.advance_day(is_tilled)
	# After the curse, so lanterns can push back the same night.
	_heal_from_buildings()
	_water_from_buildings()
	_refresh_soil_edges()
	_refresh_crop_needs()
	SaveGame.farm_state = _to_state()


## Food crops can't protect themselves: the curse blights them, and the land under them stays.
func _curse_comes_back() -> void:
	var blighted := 0
	for cell in healing.marked:
		if crops.has(cell) and healing.is_at_risk(cell, _can_curse_take):
			crops[cell].blighted = true
			blighted += 1
	if blighted > 0:
		GameState.notice.emit("The curse blighted %s." % ("1 crop" if blighted == 1 else "%d crops" % blighted))
	var lost := healing.curse_returns(_can_curse_take)
	for cell in lost:
		untill(cell)
	if not lost.is_empty():
		GameState.notice.emit("The curse took back %s overnight." % _tiles_text(lost.size()))


func _on_day_started() -> void:
	healing.mark_tonight(_can_curse_take)
	if not healing.marked.is_empty():
		GameState.notice.emit("The curse has marked %s for tonight." % _tiles_text(healing.marked.size()))


func _tiles_text(count: int) -> String:
	return "1 tile" if count == 1 else "%d tiles" % count


## Buildings are never lost. Crops and bare soil can't protect themselves, so they need a
## healing lantern, a restored shrine or a watered ward plant nearby.
func _can_curse_take(cell: Vector2i) -> bool:
	if builder.placed.has(cell) or gathering.spots.has(cell):
		return false
	if crops.has(cell) and (crops[cell].blighted or crops[cell].data.ward_radius > 0):
		return false
	return not healing.shrine_protects(cell) and not _lantern_protects(cell) and not _ward_protects(cell)


func _ward_protects(cell: Vector2i) -> bool:
	for center in crops:
		var radius := ward_reach(center)
		if radius > 0 and tiles_apart(cell, center) <= radius:
			return true
	return false


func _lantern_protects(cell: Vector2i) -> bool:
	for center in builder.placed:
		var radius: int = builder.placed[center]["data"].guard_radius
		if radius > 0 and tiles_apart(cell, center) <= radius:
			return true
	return false


## Without this, every tile ever tilled would stay soil for good.
func _age_empty_soil() -> void:
	for cell in soil.get_used_cells():
		if crops.has(cell):
			soil_idle.erase(cell)
			continue
		soil_idle[cell] = soil_idle.get(cell, 0) + 1
		if soil_idle[cell] >= GameState.BALANCE.soil_idle_nights:
			untill(cell)


## An icon only when a crop needs water. A ripe crop shows it by its own look.
func _refresh_crop_needs() -> void:
	for cell in crops:
		var crop := crops[cell]
		crop.show_need(null if crop.can_harvest() or is_watered(cell) else WATER_ICON)
		crop.show_guard(ward_reach(cell))


## Grass over the field's edge, and wet soil over dry. Call after any soil change:
## tilling, untilling, watering, drying, or loading.
func _refresh_soil_edges() -> void:
	soil_edges.refresh(ground, soil)
	wet_edges.refresh(soil)


## Wells water nearby soil for the new day. Also runs after loading, because watered soil
## isn't saved: a save is always made in the morning, so this puts the water back.
func _water_from_buildings() -> void:
	for center in builder.placed:
		var radius: int = builder.placed[center]["data"].water_radius
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var cell: Vector2i = center + Vector2i(x, y)
				if is_tilled(cell):
					water(cell)


## Each healing building pushes the curse back a little while the player sleeps.
func _heal_from_buildings() -> void:
	var healed := 0
	for cell in builder.placed:
		var radius: int = builder.placed[cell]["data"].heal_radius
		if radius > 0 and healing.heal_nearest(cell, radius):
			healed += 1
	if healed > 0:
		GameState.notice.emit("Your lanterns healed %s overnight." % _tiles_text(healed))


## Called after the soil dries, so only tilled cells need saving, not watered ones.
func _to_state() -> Dictionary:
	var saved_crops: Array[Dictionary] = []
	for cell in crops:
		saved_crops.append({"cell": cell, "id": crops[cell].data.id, "days": crops[cell].days_grown, "blighted": crops[cell].blighted})
	return {
		"cleansed": healing.cleansed.duplicate(),
		"dug_finds": healing.dug_finds.duplicate(),
		"tilled": soil.get_used_cells(),
		"soil_idle": soil_idle.duplicate(),
		"crops": saved_crops,
		"shrine": healing.shrine.restored,
		"gathered": gathering.to_state(),
		"buildings": builder.to_state(),
		"starting_objects": builder.starting_left(),
	}


func _restore(state: Dictionary) -> void:
	healing.restore(state.get("cleansed", []), state.get("shrine", false), state.get("dug_finds", []))
	gathering.populate(ground, crops_parent, player)
	gathering.restore(state.get("gathered", []))
	builder.adopt_starting(state.get("starting_objects"))
	builder.restore(state.get("buildings", []))
	for cell: Vector2i in state.get("tilled", []):
		till(cell)
	# Saves from before this existed count all their soil as freshly used.
	soil_idle.assign(state.get("soil_idle", {}))
	for saved: Dictionary in state.get("crops", []):
		var data := Inventory.crop_by_id(saved["id"])
		if data:
			var crop := _add_crop(saved["cell"], data)
			crop.set_days_grown(saved["days"])
			crop.blighted = saved.get("blighted", false)
	_clear_under_starting_well()
	# Last, because restoring the soil above leaves it all dry.
	_water_from_buildings()
	_refresh_soil_edges()
	_refresh_crop_needs()


## The starting well is newer than some saves, which may have farmed its tile. It's a fixed
## object like the house, because the save's list of map objects would remove a movable one.
func _clear_under_starting_well() -> void:
	var well: Node2D = crops_parent.get_node("StartingWell")
	var cell := ground.local_to_map(ground.to_local(well.global_position) - BUILDING_BASE)
	if crops.has(cell):
		crops[cell].queue_free()
		crops.erase(cell)
	untill(cell)


func _limit_camera() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	var used := ground.get_used_rect()
	var tile := ground.tile_set.tile_size
	camera.limit_left = used.position.x * tile.x
	camera.limit_top = used.position.y * tile.y
	camera.limit_right = used.end.x * tile.x
	camera.limit_bottom = used.end.y * tile.y


## Why the picked combat button can't fight.
func _no_weapon_text() -> String:
	var item := Inventory.combat_item(Inventory.combat_pick)
	if item == &"bow" and Inventory.carried(item) > 0:
		return "No arrows. Make some at the workbench, or pick another combat button."
	if BasicWeapons.throws(item) and Inventory.carried(item) > 0:
		return "No stones in the bag. Break rocks, or take some from storage."
	return "No weapon on this combat button. Set one on the Modes page."
