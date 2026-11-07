extends Node
## Everything the player owns, and the lists of things that can be owned.
## Registered as the Inventory autoload. Buying, crafting and shipping live here.

signal inventory_changed

const BALANCE: GameBalance = preload("res://data/balance.tres")

const START_SEEDS: Dictionary[StringName, int] = {&"radish": 10, &"carrot": 5, &"pumpkin": 3}

const CROPS: Array[CropData] = [
	preload("res://data/crops/radish.tres"),
	preload("res://data/crops/carrot.tres"),
	preload("res://data/crops/pumpkin.tres"),
	preload("res://data/crops/wardthorn.tres"),
]

const CURSE_SHARD: MaterialData = preload("res://data/materials/curse_shard.tres")
const MATERIALS: Array[MaterialData] = [
	preload("res://data/materials/wood.tres"),
	preload("res://data/materials/stone.tres"),
	preload("res://data/materials/curse_shard.tres"),
]

const RECIPES: Array[RecipeData] = [
	preload("res://data/recipes/holy_water.tres"),
	preload("res://data/recipes/purifying_hoe.tres"),
	preload("res://data/recipes/lantern_post.tres"),
	preload("res://data/recipes/fence.tres"),
	preload("res://data/recipes/well.tres"),
	preload("res://data/recipes/sword.tres"),
	preload("res://data/recipes/strong_holy_water.tres"),
]

## Loaded when the game starts, not preloaded: the shipping box script uses Inventory,
## so preloading it here would be a loop and leave it half loaded. Treat it as a constant.
var BUILDINGS: Array[BuildingData] = [
	load("res://data/buildings/lantern_post.tres"),
	load("res://data/buildings/fence.tres"),
	load("res://data/buildings/well.tres"),
	load("res://data/buildings/shipping_box.tres"),
	load("res://data/buildings/workbench.tres"),
	load("res://data/buildings/old_lantern_post.tres"),
]

var money := 0
## Seed counts by crop id.
var seeds: Dictionary[StringName, int] = START_SEEDS.duplicate()
## Harvested crop counts by crop id.
var harvest: Dictionary[StringName, int] = {}
## Gathered material counts by material id.
var materials: Dictionary[StringName, int] = {}
## Crafted buildings not placed yet, by building id.
var buildings: Dictionary[StringName, int] = {}
## Crops in the shipping box by crop id, paid when the day ends.
var shipped: Dictionary[StringName, int] = {}
## Uses of holy water owned. Each one cleanses a patch of cursed land.
var holy_water: int = BALANCE.start_holy_water
## Like holy water, but it heals a bigger patch.
var strong_holy_water := 0
## Not saved: saves happen in the morning, when this is always 0.
var holy_water_sold_today := 0
## Seeds of limited crops sold today, by crop id. Not saved, for the same reason.
var seeds_sold_today: Dictionary[StringName, int] = {}
## The crafted upgrade: the hoe also heals single cursed tiles, a few times a day.
var has_purifying_hoe := false
var has_sword := false
## Purifying uses left today. Full every morning, so only owning the hoe is saved.
var hoe_uses_left := 0
## Waters left in the can. Full every morning, so it isn't saved.
var can_water: int = BALANCE.can_capacity


func crop_by_id(id: StringName) -> CropData:
	for crop in CROPS:
		if crop.id == id:
			return crop
	return null


func building_by_id(id: StringName) -> BuildingData:
	for building in BUILDINGS:
		if building.id == id:
			return building
	return null


func seed_count(crop: CropData) -> int:
	return seeds.get(crop.id, 0)


func harvest_count(crop: CropData) -> int:
	return harvest.get(crop.id, 0)


## Crafting can leave a crop at a count of 0, so an entry alone doesn't mean there's a harvest.
func has_harvest() -> bool:
	return harvest.values().any(func(count: int) -> bool: return count > 0)


func material_count(material: MaterialData) -> int:
	return materials.get(material.id, 0)


func building_count(building: BuildingData) -> int:
	return buildings.get(building.id, 0)


## What everything in the shipping box will earn overnight.
func shipped_value() -> int:
	var total := 0
	for crop in CROPS:
		total += shipped.get(crop.id, 0) * crop.sell_price
	return total


## Removes one seed. Returns false if there are none left.
func use_seed(crop: CropData) -> bool:
	if seed_count(crop) <= 0:
		return false
	seeds[crop.id] -= 1
	inventory_changed.emit()
	return true


func add_harvest(crop: CropData) -> void:
	harvest[crop.id] = harvest_count(crop) + 1
	inventory_changed.emit()


## A blighted crop can't be sold, but it leaves a little money and a curse shard.
func take_blighted_crop() -> void:
	money += BALANCE.blighted_crop_money
	add_material(CURSE_SHARD, 1)
	GameState.notice.emit("+%d money, +1 %s" % [BALANCE.blighted_crop_money, CURSE_SHARD.display_name])


func add_material(material: MaterialData, amount: int) -> void:
	materials[material.id] = material_count(material) + amount
	inventory_changed.emit()


## How much of a recipe's ingredient the player has.
func owned(need: RecipeNeed) -> int:
	if need.holy_water:
		return holy_water
	return harvest_count(need.crop) if need.crop else material_count(need.material)


## Whether this is a one-time recipe the player has already made.
func already_made(recipe: RecipeData) -> bool:
	match recipe.result:
		RecipeData.Result.PURIFYING_HOE:
			return has_purifying_hoe
		RecipeData.Result.SWORD:
			return has_sword
	return false


func can_craft(recipe: RecipeData) -> bool:
	if already_made(recipe):
		return false
	for need in recipe.needs:
		if owned(need) < need.amount:
			return false
	return true


## Uses up the ingredients and gives the result. Returns false if something is missing.
func craft(recipe: RecipeData) -> bool:
	if not can_craft(recipe):
		return false
	for need in recipe.needs:
		if need.holy_water:
			holy_water -= need.amount
		elif need.crop:
			harvest[need.crop.id] -= need.amount
		else:
			materials[need.material.id] -= need.amount
	match recipe.result:
		RecipeData.Result.HOLY_WATER:
			holy_water += recipe.result_amount
		RecipeData.Result.BUILDING:
			add_building(recipe.building, recipe.result_amount)
		RecipeData.Result.PURIFYING_HOE:
			has_purifying_hoe = true
			hoe_uses_left = BALANCE.hoe_daily_uses
		RecipeData.Result.SWORD:
			has_sword = true
		RecipeData.Result.STRONG_HOLY_WATER:
			strong_holy_water += recipe.result_amount
	inventory_changed.emit()
	return true


## Moves every harvested crop into the shipping box.
func ship_all() -> void:
	if not harvest.is_empty():
		Progress.record_action("ship")
	for id in harvest:
		shipped[id] = shipped.get(id, 0) + harvest[id]
	harvest.clear()
	inventory_changed.emit()


## How many more the stall will sell today, for a crop with a daily_stock.
func seeds_left_today(crop: CropData) -> int:
	return crop.daily_stock - seeds_sold_today.get(crop.id, 0)


## Buys one seed. Returns false if there isn't enough money, or the stall has sold out.
func buy_seed(crop: CropData) -> bool:
	if money < crop.seed_price or (crop.daily_stock > 0 and seeds_left_today(crop) <= 0):
		return false
	money -= crop.seed_price
	seeds[crop.id] = seed_count(crop) + 1
	seeds_sold_today[crop.id] = seeds_sold_today.get(crop.id, 0) + 1
	inventory_changed.emit()
	return true


func holy_water_left_today() -> int:
	return BALANCE.holy_water_daily_limit - holy_water_sold_today


## Buys one holy water. Returns false if there isn't enough money.
func buy_holy_water() -> bool:
	if money < BALANCE.holy_water_price or holy_water_left_today() <= 0:
		return false
	money -= BALANCE.holy_water_price
	holy_water += 1
	holy_water_sold_today += 1
	inventory_changed.emit()
	return true


func add_building(building: BuildingData, amount: int = 1) -> void:
	buildings[building.id] = building_count(building) + amount
	inventory_changed.emit()


## Removes one crafted building. Returns false if there are none left.
func use_building(building: BuildingData) -> bool:
	if building_count(building) <= 0:
		return false
	buildings[building.id] -= 1
	inventory_changed.emit()
	return true


## Spends one water from the can. Returns false if it's empty.
func use_can_water() -> bool:
	if can_water <= 0:
		return false
	can_water -= 1
	inventory_changed.emit()
	return true


func fill_can() -> void:
	can_water = BALANCE.can_capacity
	inventory_changed.emit()


## Spends one of today's purifying uses. Returns false if there are none left.
func use_purifying_hoe() -> bool:
	if not has_purifying_hoe or hoe_uses_left <= 0:
		return false
	hoe_uses_left -= 1
	inventory_changed.emit()
	return true


func use_strong_holy_water() -> bool:
	if strong_holy_water <= 0:
		return false
	strong_holy_water -= 1
	inventory_changed.emit()
	return true


## Removes holy water. Returns false if there isn't enough.
func use_holy_water(amount: int = 1) -> bool:
	if holy_water < amount:
		return false
	holy_water -= amount
	inventory_changed.emit()
	return true


## Gives the player what was buried.
func give_find(find: BuriedFind) -> void:
	match find.kind:
		BuriedFind.Kind.MONEY:
			money += find.amount
			GameState.notice.emit("You dug up %d money!" % find.amount)
		BuriedFind.Kind.HOLY_WATER:
			holy_water += find.amount
			GameState.notice.emit("You dug up %d holy water!" % find.amount)
		BuriedFind.Kind.SEEDS:
			seeds[find.crop.id] = seed_count(find.crop) + find.amount
			GameState.notice.emit("You dug up %d %s seeds!" % [find.amount, find.crop.display_name.to_lower()])
	inventory_changed.emit()


## Pays for everything in the shipping box. Progress calls this as the day ends.
func pay_shipped() -> void:
	money += shipped_value()
	shipped.clear()
	inventory_changed.emit()


## Takes the fainting fee and returns how much it was.
func lose_faint_money() -> int:
	var lost: int = money * BALANCE.faint_money_percent / 100
	money -= lost
	inventory_changed.emit()
	return lost


## Refills what comes back every morning. Progress calls this as a new day starts.
func start_day() -> void:
	holy_water_sold_today = 0
	seeds_sold_today.clear()
	can_water = BALANCE.can_capacity
	_refill_hoe()


func reset() -> void:
	money = 0
	seeds = START_SEEDS.duplicate()
	harvest.clear()
	materials.clear()
	buildings.clear()
	shipped.clear()
	holy_water = BALANCE.start_holy_water
	strong_holy_water = 0
	holy_water_sold_today = 0
	seeds_sold_today.clear()
	has_purifying_hoe = false
	has_sword = false
	hoe_uses_left = 0
	can_water = BALANCE.can_capacity


## The shipping box isn't saved: it's always empty here, because end_day() pays it first.
func save_to(file: ConfigFile) -> void:
	file.set_value("game", "money", money)
	file.set_value("game", "seeds", seeds)
	file.set_value("game", "harvest", harvest)
	file.set_value("game", "materials", materials)
	file.set_value("game", "buildings", buildings)
	file.set_value("game", "holy_water", holy_water)
	file.set_value("game", "strong_holy_water", strong_holy_water)
	file.set_value("game", "purifying_hoe", has_purifying_hoe)
	file.set_value("game", "sword", has_sword)


func load_from(file: ConfigFile) -> void:
	money = file.get_value("game", "money", money)
	seeds.assign(file.get_value("game", "seeds", seeds))
	harvest.assign(file.get_value("game", "harvest", harvest))
	materials.assign(file.get_value("game", "materials", materials))
	buildings.assign(file.get_value("game", "buildings", buildings))
	holy_water = file.get_value("game", "holy_water", holy_water)
	strong_holy_water = file.get_value("game", "strong_holy_water", strong_holy_water)
	has_purifying_hoe = file.get_value("game", "purifying_hoe", has_purifying_hoe)
	has_sword = file.get_value("game", "sword", has_sword)
	_refill_hoe()


func _refill_hoe() -> void:
	if has_purifying_hoe:
		hoe_uses_left = BALANCE.hoe_daily_uses
