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
## Finds by cell. A find is gone once its cell is in `cleansed`, so finds aren't saved.
var finds: Dictionary[Vector2i, BuriedFind] = {}
## How many cells could ever be healed.
var _cursed_total := 0
## The glimmer over each find not dug up yet.
var _glimmers: Dictionary[Vector2i, Node2D] = {}

@onready var ground: TileMapLayer = get_node(ground_path)
@onready var curse_edges: CurseEdges = get_node(curse_edges_path)
@onready var shrine: Shrine = get_node(shrine_path)


func _ready() -> void:
	for find in FIND_TABLE.finds:
		finds[find.cell] = find
	shrine.activated.connect(_on_shrine_activated)


## Rebuilds healed land from a save, then sets up what depends on it.
func restore(saved_cells: Array, shrine_restored: bool) -> void:
	_cursed_total = ground.get_used_cells_by_id(Farm.Source.CURSED).filter(is_cleansable).size()
	shrine.restored = shrine_restored
	for cell: Vector2i in saved_cells:
		_heal(cell)
	_add_glimmers()
	curse_edges.refresh(ground)
	_report_progress()


## The map's outer ring can't be healed: nothing else stops the player walking off the map.
func is_cleansable(cell: Vector2i) -> bool:
	return ground.get_cell_source_id(cell) == Farm.Source.CURSED and ground.get_used_rect().grow(-1).has_point(cell)


## The cells a cleanse centered here would heal.
func cleansable_cells(center: Vector2i) -> Array[Vector2i]:
	var radius := GameState.BALANCE.cleanse_radius
	var cells: Array[Vector2i] = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var cell := center + Vector2i(x, y)
			if is_cleansable(cell):
				cells.append(cell)
	return cells


func cleanse(center: Vector2i) -> void:
	var cells := cleansable_cells(center)
	if cells.is_empty() or not GameState.use_holy_water():
		return
	_cleanse_cells(cells, center)


## Whether the purifying hoe would heal this cell.
func can_purify(cell: Vector2i) -> bool:
	return GameState.hoe_uses_left > 0 and is_cleansable(cell)


## Heals one cell with the purifying hoe.
func purify(cell: Vector2i) -> void:
	if is_cleansable(cell) and GameState.use_purifying_hoe():
		_cleanse_cells([cell], cell)


func _cleanse_cells(cells: Array[Vector2i], center: Vector2i) -> void:
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
		var center := ground.local_to_map(ground.to_local(shrine.global_position))
		_cleanse_cells(_cursed_cells_around(center, GameState.BALANCE.shrine_radius), center)
		GameState.notice.emit("The old shrine is restored! The land around it heals.")


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


func _dig_up(cell: Vector2i) -> void:
	GameState.give_find(finds[cell])
	_glimmers[cell].queue_free()
	_glimmers.erase(cell)


func _add_glimmers() -> void:
	for cell in finds:
		if not cleansed.has(cell):
			var glimmer: Node2D = GLIMMER_SCENE.instantiate()
			glimmer.position = ground.map_to_local(cell)
			add_child(glimmer)
			_glimmers[cell] = glimmer


func _report_progress() -> void:
	GameState.set_healed_percent(100.0 * cleansed.size() / _cursed_total)
