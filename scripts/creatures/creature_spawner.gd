class_name CreatureSpawner
extends Node
## Each morning, creatures rise on clean land beside the curse. They vanish at night, so
## they're never saved, and every morning starts fresh.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
## Toughest first: the first one allowed at a cell is the one that appears there.
const CREATURES: Array[CreatureData] = [
	preload("res://data/creatures/hollow.tres"),
	preload("res://data/creatures/shade.tres"),
]
## They never appear closer than this to the player, in pixels.
const MIN_PLAYER_DISTANCE := 224.0
## Or closer than this to each other, so they don't arrive as a crowd.
const MIN_SPACING := 96.0
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

var creatures: Array[Creature] = []

var _farm: Farm
var _parent: Node2D
var _player: Node2D


## `parent` must be the Y-sorted World.
func setup(farm: Farm, parent: Node2D, player: Node2D) -> void:
	_farm = farm
	_parent = parent
	_player = player


func count_for_today() -> int:
	var balance := GameState.BALANCE
	if Progress.day < balance.creature_first_day:
		return 0
	var extra := int(Progress.healed_percent / balance.creature_heal_percent_each)
	return mini(balance.creature_base_count + extra, balance.creature_max_count)


func spawn_for_today() -> void:
	clear()
	var wanted := count_for_today()
	if wanted == 0:
		return
	if Progress.day == GameState.BALANCE.creature_first_day:
		GameState.notice.emit("Something stirs at the edge of the curse...")
	var rng := RandomNumberGenerator.new()
	# Seeded by the day, so a morning always plays out the same way.
	rng.seed = Progress.day
	var cells := spawn_cells()
	_shuffle(cells, rng)
	var taken: Array[Vector2] = []
	for cell in cells:
		if taken.size() == wanted:
			break
		var at := _world_position(cell)
		if _far_from_all(at, taken):
			taken.append(at)
			_spawn(at, creature_for(cell))


## Creatures get stronger toward the east, closer to the cursed heart.
func creature_for(cell: Vector2i) -> CreatureData:
	for data in CREATURES:
		if cell.x >= data.min_cell_x:
			return data
	return CREATURES[CREATURES.size() - 1]


## The creature nearest to a point, if one is this close in pixels.
func nearest_within(point: Vector2, distance: float) -> Creature:
	var nearest: Creature = null
	var best := distance
	for creature in creatures:
		if is_instance_valid(creature) and creature.global_position.distance_to(point) <= best:
			best = creature.global_position.distance_to(point)
			nearest = creature
	return nearest


func clear() -> void:
	for creature in creatures:
		if is_instance_valid(creature):
			creature.queue_free()
	creatures.clear()


## Clean cells beside the curse that the player can walk to, away from lanterns and the player.
func spawn_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in _reachable_cells():
		if _touches_curse(cell) and _farm.is_farmable(cell) and not _in_light(_world_position(cell)):
			if _world_position(cell).distance_to(_player.global_position) >= MIN_PLAYER_DISTANCE:
				cells.append(cell)
	return cells


## Clearings cut off by the curse are left out: a creature there could never reach the player.
func _reachable_cells() -> Array[Vector2i]:
	var ground := _farm.ground
	var start := ground.local_to_map(ground.to_local(_player.global_position))
	var seen: Dictionary[Vector2i, bool] = {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var cell: Vector2i = todo.pop_back()
		for side in SIDES:
			var next: Vector2i = cell + side
			if not seen.has(next) and ground.get_cell_source_id(next) == Farm.Source.GRASS:
				seen[next] = true
				todo.append(next)
	return seen.keys()


func _touches_curse(cell: Vector2i) -> bool:
	for side in SIDES:
		if _farm.ground.get_cell_source_id(cell + side) == Farm.Source.CURSED:
			return true
	return false


func _in_light(at: Vector2) -> bool:
	for light: Node2D in get_tree().get_nodes_in_group("lantern_light"):
		if at.distance_to(light.global_position) < GameState.BALANCE.lantern_safe_radius + 8.0:
			return true
	return false


func _far_from_all(at: Vector2, others: Array[Vector2]) -> bool:
	for other in others:
		if at.distance_to(other) < MIN_SPACING:
			return false
	return true


func _world_position(cell: Vector2i) -> Vector2:
	return _farm.ground.to_global(_farm.ground.map_to_local(cell))


## Array.shuffle() can't use a seed, so this does the same with our own generator.
func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := cells[i]
		cells[i] = cells[j]
		cells[j] = swap


func _spawn(at: Vector2, data: CreatureData) -> void:
	var creature: Creature = CREATURE_SCENE.instantiate()
	creature.data = data
	creature.position = _parent.to_local(at)
	_parent.add_child(creature)
	creatures.append(creature)
