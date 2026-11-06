class_name Healing
extends Node2D
## Everything about healing cursed land: which cells can heal, holy water, the shrine,
## buried finds and the progress score. Glimmers and effects are drawn as children of this node.

## Land just healed by the player, not land restored from a save.
signal land_healed(cells: Array[Vector2i])

const FIND_TABLE: BuriedFindTable = preload("res://data/buried_finds.tres")
const CLEANSE_EFFECT_SCENE := preload("res://scenes/farm/cleanse_effect.tscn")
const GLIMMER_SCENE := preload("res://scenes/farm/find_glimmer.tscn")

@export var ground_path: NodePath
@export var curse_edges_path: NodePath
@export var shrine_path: NodePath

## Cells healed so far. ground.tscn always starts cursed, so these are what gets saved.
var cleansed: Array[Vector2i] = []
## Finds still buried, by cell.
var finds: Dictionary[Vector2i, BuriedFind] = {}
## Finds already dug up. Saved, because their land can turn cursed again and mustn't pay twice.
var dug_finds: Array[Vector2i] = []
## Tiles the curse picked this morning. Not saved: the same day and land pick the same tiles.
var marked: Array[Vector2i] = []
## How many cells could ever be healed.
var _cursed_total := 0
## The glimmer over each find not dug up yet.
var _glimmers: Dictionary[Vector2i, Node2D] = {}
var _marks := CurseMarks.new()

@onready var ground: TileMapLayer = get_node(ground_path)
@onready var curse_edges: CurseEdges = get_node(curse_edges_path)
@onready var shrine: Shrine = get_node(shrine_path)


func _ready() -> void:
	for find in FIND_TABLE.finds:
		finds[find.cell] = find
	shrine.activated.connect(_on_shrine_activated)
	add_child(_marks)


## Rebuilds healed land from a save, then sets up what depends on it.
func restore(saved_cells: Array, shrine_restored: bool, saved_dug_finds: Array = []) -> void:
	_cursed_total = ground.get_used_cells_by_id(Farm.Source.CURSED).filter(is_cleansable).size()
	shrine.restored = shrine_restored
	for cell: Vector2i in saved_cells:
		_heal(cell)
	# Saves from before land could return only know a find is gone by its cell being healed.
	for cell: Vector2i in saved_dug_finds + saved_cells:
		_forget_find(cell)
	_add_glimmers()
	curse_edges.refresh(ground)
	_report_progress()


## The map's outer ring can't be healed: nothing else stops the player walking off the map.
func is_cleansable(cell: Vector2i) -> bool:
	return ground.get_cell_source_id(cell) == Farm.Source.CURSED and ground.get_used_rect().grow(-1).has_point(cell)


## How many tiles out holy water reaches.
func radius_for(strong: bool) -> int:
	return GameState.BALANCE.strong_cleanse_radius if strong else GameState.BALANCE.cleanse_radius


## The cells a cleanse centered here would heal.
func cleansable_cells(center: Vector2i, strong: bool = false) -> Array[Vector2i]:
	var radius := radius_for(strong)
	var cells: Array[Vector2i] = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var cell := center + Vector2i(x, y)
			if is_cleansable(cell):
				cells.append(cell)
	return cells


func cleanse(center: Vector2i, strong: bool = false) -> void:
	var cells := cleansable_cells(center, strong)
	if cells.is_empty():
		return
	var paid := GameState.use_strong_holy_water() if strong else GameState.use_holy_water()
	if paid:
		_cleanse_cells(cells, center)


## Heals the closest cursed cell within `radius`. Returns false if there's none in range.
func heal_nearest(center: Vector2i, radius: int) -> bool:
	var cells := _cursed_cells_around(center, radius)
	if cells.is_empty():
		return false
	var nearest := cells[0]
	for cell in cells:
		if Vector2(cell - center).length() < Vector2(nearest - center).length():
			nearest = cell
	_cleanse_cells([nearest], nearest)
	return true


## Whether the purifying hoe would heal this cell.
func can_purify(cell: Vector2i) -> bool:
	return GameState.hoe_uses_left > 0 and is_cleansable(cell)


## Heals one cell with the purifying hoe.
func purify(cell: Vector2i) -> void:
	if is_cleansable(cell) and GameState.use_purifying_hoe():
		_cleanse_cells([cell], cell)


## Each morning, the curse picks the healed tiles along its edge that it will take tonight.
## `can_take` says whether a tile is free to lose. Seeded by the day, so a restart picks the same.
func mark_tonight(can_take: Callable) -> void:
	marked.clear()
	if GameState.day >= GameState.BALANCE.curse_return_first_day:
		var at_risk: Array[Vector2i] = []
		for cell in cleansed:
			if _touches_curse(cell) and can_take.call(cell):
				at_risk.append(cell)
		var rng := RandomNumberGenerator.new()
		rng.seed = GameState.day
		for i in mini(GameState.BALANCE.curse_return_per_night, at_risk.size()):
			marked.append(at_risk.pop_at(rng.randi_range(0, at_risk.size() - 1)))
	refresh_marks(can_take)


## Shows only what's still at risk: using a marked tile saves it, and the mark goes.
func refresh_marks(can_take: Callable) -> void:
	var rects: Array[Rect2] = []
	var size := Vector2(ground.tile_set.tile_size)
	for cell in marked:
		if is_at_risk(cell, can_take):
			rects.append(Rect2(ground.map_to_local(cell) - size / 2.0, size))
	_marks.show_tiles(rects)


## Healing the land around a marked tile saves it too, because the curse no longer touches it.
func is_at_risk(cell: Vector2i, can_take: Callable) -> bool:
	return marked.has(cell) and cleansed.has(cell) and _touches_curse(cell) and can_take.call(cell)


## Overnight, the curse takes the marked tiles still at risk. Returns how many it took.
func curse_returns(can_take: Callable) -> int:
	var taken := marked.filter(func(cell: Vector2i) -> bool: return is_at_risk(cell, can_take))
	marked.clear()
	refresh_marks(can_take)
	if taken.is_empty():
		return 0
	for cell: Vector2i in taken:
		_curse(cell)
	curse_edges.refresh(ground)
	_report_progress()
	return taken.size()


## `sound` lets the shrine play its own bigger sound instead.
func _cleanse_cells(cells: Array[Vector2i], center: Vector2i, sound: StringName = &"cleanse") -> void:
	Audio.play(sound)
	for cell in cells:
		_heal(cell)
		if finds.has(cell):
			_dig_up(cell)
	var effect: CleanseEffect = CLEANSE_EFFECT_SCENE.instantiate()
	add_child(effect)
	effect.play(cells, center, ground)
	curse_edges.refresh(ground)
	_report_progress()
	land_healed.emit(cells)


func _on_shrine_activated() -> void:
	var cost := GameState.BALANCE.shrine_cost
	if shrine.restored:
		GameState.notice.emit("The shrine is at peace.")
	elif not GameState.use_holy_water(cost):
		GameState.notice.emit("The shrine needs %d holy water." % cost)
	else:
		shrine.restored = true
		var center := _shrine_cell()
		_cleanse_cells(_cursed_cells_around(center, GameState.BALANCE.shrine_radius), center, &"shrine")
		GameState.notice.emit("The old shrine is restored! The land around it heals.")


## A restored shrine keeps the curse away from all the land it healed.
func shrine_protects(cell: Vector2i) -> bool:
	return shrine.restored and Vector2(cell - _shrine_cell()).length() <= GameState.BALANCE.shrine_radius


func _shrine_cell() -> Vector2i:
	return ground.local_to_map(ground.to_local(shrine.global_position))


## Healable cells in a circle, for a cleanse bigger than holy water's square patch.
func _cursed_cells_around(center: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var offset := Vector2i(x, y)
			if Vector2(offset).length() <= radius and is_cleansable(center + offset):
				cells.append(center + offset)
	return cells


func _heal(cell: Vector2i) -> void:
	ground.set_cell(cell, Farm.Source.GRASS, Farm.texture_coords(cell))
	cleansed.append(cell)


func _curse(cell: Vector2i) -> void:
	ground.set_cell(cell, Farm.Source.CURSED, Farm.texture_coords(cell))
	cleansed.erase(cell)


func _touches_curse(cell: Vector2i) -> bool:
	for next_door in ground.get_surrounding_cells(cell):
		if ground.get_cell_source_id(next_door) == Farm.Source.CURSED:
			return true
	return false


func _dig_up(cell: Vector2i) -> void:
	GameState.give_find(finds[cell])
	Audio.play(&"find")
	_glimmers[cell].queue_free()
	_glimmers.erase(cell)
	_forget_find(cell)


func _forget_find(cell: Vector2i) -> void:
	if finds.erase(cell):
		dug_finds.append(cell)


func _add_glimmers() -> void:
	for cell in finds:
		var glimmer: Node2D = GLIMMER_SCENE.instantiate()
		glimmer.position = ground.map_to_local(cell)
		add_child(glimmer)
		_glimmers[cell] = glimmer


func _report_progress() -> void:
	GameState.set_healed_percent(100.0 * cleansed.size() / _cursed_total)
