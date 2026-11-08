extends SceneTree
## Estimates the game's pace from the real map and data files: how much healing the path to
## the first shrine needs, and how many days a sensible player takes to get there.
## It changes nothing; it only prints numbers. Run it after changing balance numbers.
##
## Usage:
##   godot --headless --path <project> --script tools/balance_check.gd
##
## The simulated player, each day: harvests and ships what's ripe, keeps every plot planted
## (seeds owned first, then the crop earning most per day they can afford), spends what's
## left on holy water, and uses it all on the path. Plots are the limit, because the game has
## no energy bar: only how many tiles you're willing to water by hand every day.
## Left out: gathering and crafting, creatures, walking time, lanterns and the purifying hoe.
##
## The curse takes land back each night, so holy water also goes on repairs. How much depends on
## where the tiles fall, so two cases are shown: tiles close together (one use mends 9) and
## scattered (one use mends 3). Not every lost tile really needs mending, so both lean cautious.
## The curse growing with healed land isn't counted: this path heals too little for it to matter.

const HOME := Vector2i(28, 9)
const SHRINE := Vector2i(69, 12)
const CURSED := 1
## Standing at the curse, a 3×3 patch moves the edge forward 2 tiles.
const TILES_PER_USE := 2
const PLOT_COUNTS: Array[int] = [8, 12, 20, 40]
const MAX_DAYS := 200
const RESULT_TARGET := "10 to 15 days (the playtest plan's starting target)"
## Tiles lost a night, and tiles one holy water mends. The first row is the game without the curse.
const CURSE_CASES: Array[Array] = [[0, 9], [1, 9], [1, 3], [2, 9], [2, 3], [3, 9], [3, 3]]

var _ground: TileMapLayer
var _balance: Resource
var _crops: Array[Resource] = []


func _init() -> void:
	_ground = (load("res://scenes/farm/ground.tscn") as PackedScene).instantiate()
	_balance = load("res://data/balance.tres")
	for id: Variant in ["radish", "carrot", "pumpkin"]:
		_crops.append(load("res://data/crops/%s.tres" % id))
	var path := _cheapest_path()
	var uses := ceili(float(path.size()) / TILES_PER_USE)
	print("Cursed tiles on the shortest path from the house to the shrine: ", path.size())
	print("Holy water uses to open it: %d, plus %d for the shrine = %d" % [uses, _balance.shrine_cost, uses + _balance.shrine_cost])
	print("Cost at %d each: %d money, before buried finds" % [_balance.holy_water_price, (uses + _balance.shrine_cost) * _balance.holy_water_price])
	print("")
	for curse_case in CURSE_CASES:
		print("Curse takes %d a night, one holy water mends %d:" % curse_case)
		print("plots | first holy water | path open | shrine restored | money earned by then")
		for plots in PLOT_COUNTS:
			print(_simulate(plots, path, curse_case[0], curse_case[1]))
		print("")
	print("Target: ", RESULT_TARGET)
	_ground.free()
	quit()


## The fewest cursed tiles to heal between the house and the shrine (clean tiles are free).
## The map's outer ring can't be healed.
func _cheapest_path() -> Array[Vector2i]:
	var rect := _ground.get_used_rect().grow(-1)
	var cost: Dictionary[Vector2i, int] = {HOME: 0}
	var came_from: Dictionary[Vector2i, Vector2i] = {}
	var queue: Array[Vector2i] = [HOME]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for side: Vector2i in [Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = cell + side
			if not rect.has_point(next):
				continue
			var step := 1 if _ground.get_cell_source_id(next) == CURSED else 0
			if cost[cell] + step < cost.get(next, 1 << 30):
				cost[next] = cost[cell] + step
				came_from[next] = cell
				# Free steps go first, so this stays a correct shortest path.
				if step == 0:
					queue.push_front(next)
				else:
					queue.push_back(next)
	var path: Array[Vector2i] = []
	var at := SHRINE
	while at != HOME:
		if _ground.get_cell_source_id(at) == CURSED:
			path.push_front(at)
		at = came_from[at]
	return path


func _simulate(plot_count: int, path: Array[Vector2i], lost_per_night: int, mended_per_use: int) -> String:
	var finds: Array = (load("res://data/buried_finds.tres") as Resource).get("finds")
	var money := 0
	var earned := 0
	var holy: int = _balance.start_holy_water
	var seeds: Dictionary[Resource, int] = {_crops[0]: 10, _crops[1]: 5, _crops[2]: 3}
	## Each plot is the crop in it and the day it's ripe, or empty.
	var plots: Array[Dictionary] = []
	var at_path := 0
	var first_water := 0
	var path_open := 0
	## Holy water owed for land the curse took back.
	var repairs := 0.0
	for day in range(1, MAX_DAYS + 1):
		var shipped := 0
		var kept: Array[Dictionary] = []
		for plot in plots:
			if plot["ripe"] <= day:
				shipped += plot["crop"].sell_price
			else:
				kept.append(plot)
		plots = kept
		while plots.size() < plot_count:
			var crop := _next_crop(seeds, money)
			if not crop:
				break
			if seeds.get(crop, 0) > 0:
				seeds[crop] -= 1
			else:
				money -= crop.seed_price
			plots.append({"crop": crop, "ripe": day + crop.days_to_grow})
		if plots.size() == plot_count:
			var bought: int = mini(money / _balance.holy_water_price, _balance.holy_water_daily_limit)
			money -= bought * _balance.holy_water_price
			holy += bought
		if holy > 0 and first_water == 0:
			first_water = day
		if at_path > 0 and day > _balance.curse_return_first_day:
			repairs += float(lost_per_night) / mended_per_use
		while holy > 0 and repairs >= 1.0:
			holy -= 1
			repairs -= 1.0
		while holy > 0 and at_path < path.size():
			holy -= 1
			for find in finds:
				if absi(find.cell.x - path[at_path].x) <= 1 and absi(find.cell.y - path[at_path].y) <= 1:
					match int(find.kind):
						0:
							money += find.amount
							earned += find.amount
						1:
							seeds[_crops[0]] = seeds[_crops[0]] + find.amount
						2:
							holy += find.amount
			at_path += TILES_PER_USE
		if at_path >= path.size() and path_open == 0 and repairs < 1.0:
			path_open = day
		if path_open > 0 and holy >= _balance.shrine_cost:
			return "%5d | day %12d | day %5d | day %11d | %d" % [plot_count, first_water, path_open, day, earned]
		money += shipped
		earned += shipped
	return "%5d | not within %d days" % [plot_count, MAX_DAYS]


## Seeds owned first, fastest crop first; else the best crop per day the player can afford.
func _next_crop(seeds: Dictionary, money: int) -> Resource:
	for crop in _crops:
		if seeds.get(crop, 0) > 0:
			return crop
	var best: Resource = null
	var best_rate := 0.0
	for crop in _crops:
		var rate: float = float(crop.sell_price - crop.seed_price) / crop.days_to_grow
		if crop.seed_price <= money and rate > best_rate:
			best = crop
			best_rate = rate
	return best
