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

## By id, not preloaded: building scenes can use Inventory, which would make a load loop.
const STARTER_BUILDING := &"lantern_post"
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
	preload("res://data/recipes/bow.tres"),
	preload("res://data/recipes/arrows.tres"),
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
## The bow shoots arrows, the first weapon in the combat set once made (storage controls).
var has_bow := false
var arrows := 0
## Purifying uses left today. Full every morning, so only owning the hoe is saved.
var hoe_uses_left := 0
## Waters left in the can. Full every morning, so it isn't saved.
var can_water: int = BALANCE.can_capacity

## Storage controls only (GameState.carry_mode, docs/28_...). What the player carries, by item
## id; everything else owned waits in the storage chest. Kept in the order items came in, which
## is also the bag page's order. The totals above stay the single truth: the bag only says how
## much of each is carried, so crafting and saving work as before.
const START_BAG: Dictionary[StringName, int] = {
	&"hoe": 1, &"can": 1, &"seed_radish": 10, &"seed_carrot": 5, &"seed_pumpkin": 3, &"holy_water": 2,
}
## Carried first when an older save without a bag loads.
const OLD_SAVE_ORDER: Array[StringName] = [&"hoe", &"can", &"sword", &"holy_water", &"strong_holy_water"]
var bag: Dictionary[StringName, int] = START_BAG.duplicate()
var bag_slots: int = BALANCE.bag_start_slots
## What the big button may use on the bag page, first in the list first: seeds plant in this
## order, and the combat set's first weapon with something left is used (arrows, then the sword,
## once arrows exist). An item stays listed after it runs out, so taking more from storage puts
## it back to work.
## Farm jobs: what the big button does in Farm mode, each switched on or off on the bag page, so
## a player can water only, or keep ripe crops in the ground. The hoe, can and holy water just
## need to be carried.
const FARM_JOBS: Array[StringName] = [&"till", &"plant", &"water", &"harvest", &"gather", &"heal"]
var farm_jobs: Array[StringName] = FARM_JOBS.duplicate()
## Build jobs: what the big button does in Build mode. A picked-up building goes in the bag,
## and the player carries it wherever it goes next, the chest included.
const BUILD_JOBS: Array[StringName] = [&"place", &"pick_up"]
const START_BUILD_JOBS: Array[StringName] = [&"place", &"pick_up"]
var build_jobs: Array[StringName] = START_BUILD_JOBS.duplicate()
## Seeds to plant: as many as the player picks. The big button plants only these, first first,
## so seeds the player wants to keep are never planted by accident. New seeds never join on
## their own.
const START_PLANT_SET: Array[StringName] = [&"seed_radish", &"seed_carrot", &"seed_pumpkin"]
var plant_set: Array[StringName] = START_PLANT_SET.duplicate()
var combat_set: Array[StringName] = []
## Storage controls: whether this game got its sword and lantern post, so loading never gives
## them twice.
var starter_given := false
## Buildings Build mode places, first first. A picked-up building goes to the front.
var build_set: Array[StringName] = []


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


static func seed_item(crop: CropData) -> StringName:
	return StringName("seed_" + crop.id)


static func crop_item(crop: CropData) -> StringName:
	return StringName("crop_" + crop.id)


static func material_item(material: MaterialData) -> StringName:
	return StringName("mat_" + material.id)


static func building_item(building: BuildingData) -> StringName:
	return StringName("build_" + building.id)


## Every item that can go in the bag, in the order storage lists them.
func all_items() -> Array[StringName]:
	var items: Array[StringName] = [&"hoe", &"can", &"sword", &"bow", &"arrows", &"holy_water", &"strong_holy_water"]
	for crop in CROPS:
		items.append(seed_item(crop))
	for crop in CROPS:
		if crop.burst_radius <= 0:
			items.append(crop_item(crop))
	for material in MATERIALS:
		items.append(material_item(material))
	for building in BUILDINGS:
		items.append(building_item(building))
	return items


## How many the player owns, carried and stored together.
func total(item: StringName) -> int:
	match item:
		&"hoe", &"can":
			return 1
		&"sword":
			return 1 if has_sword else 0
		&"bow":
			return 1 if has_bow else 0
		&"arrows":
			return arrows
		&"holy_water":
			return holy_water
		&"strong_holy_water":
			return strong_holy_water
	var text := String(item)
	var id := StringName(text.substr(text.find("_") + 1))
	if text.begins_with("seed_"):
		return seeds.get(id, 0)
	if text.begins_with("crop_"):
		return harvest.get(id, 0)
	if text.begins_with("mat_"):
		return materials.get(id, 0)
	if text.begins_with("build_"):
		return buildings.get(id, 0)
	return 0


func item_name(item: StringName) -> String:
	match item:
		&"hoe":
			return "Purifying hoe" if has_purifying_hoe else "Hoe"
		&"can":
			return "Watering can"
		&"sword":
			return "Sword"
		&"bow":
			return "Bow"
		&"arrows":
			return "Arrows"
		&"holy_water":
			return "Holy water"
		&"strong_holy_water":
			return "Strong holy water"
	var text := String(item)
	var id := StringName(text.substr(text.find("_") + 1))
	if text.begins_with("seed_"):
		return crop_by_id(id).display_name + " seeds"
	if text.begins_with("crop_"):
		return crop_by_id(id).display_name
	if text.begins_with("build_"):
		return building_by_id(id).display_name
	for material in MATERIALS:
		if material.id == id:
			return material.display_name
	return text


## How many are in the bag. With the old controls everything owned counts as carried.
func carried(item: StringName) -> int:
	if not GameState.carry_mode:
		return total(item)
	return mini(bag.get(item, 0), total(item))


func stored(item: StringName) -> int:
	return total(item) - carried(item)


## What's in the bag, in the bag page's order.
func bag_items() -> Array[StringName]:
	var items: Array[StringName] = []
	for item in bag:
		if carried(item) > 0:
			items.append(item)
	return items


func used_slots() -> int:
	return bag_items().size()


## A kind already carried stacks for free; a new kind needs a free slot.
func has_room_for(item: StringName) -> bool:
	return carried(item) > 0 or used_slots() < bag_slots


## Moves from storage into the bag: all of it, or amount. Returns false if nothing moved.
func take(item: StringName, amount: int = -1) -> bool:
	var count := stored(item) if amount < 0 else mini(amount, stored(item))
	if count <= 0 or not has_room_for(item):
		return false
	var new_kind := carried(item) == 0
	bag[item] = carried(item) + count
	if new_kind:
		_join_set(item)
	inventory_changed.emit()
	return true


## Moves from the bag into storage: all of it, or amount.
func put(item: StringName, amount: int = -1) -> bool:
	var count := carried(item) if amount < 0 else mini(amount, carried(item))
	if count <= 0:
		return false
	_spend_carried(item, count)
	inventory_changed.emit()
	return true


func can_upgrade_bag() -> bool:
	return bag_slots < BALANCE.bag_max_slots


func upgrade_bag() -> bool:
	if not can_upgrade_bag() or money < BALANCE.bag_upgrade_price:
		return false
	money -= BALANCE.bag_upgrade_price
	bag_slots = mini(bag_slots + BALANCE.bag_upgrade_slots, BALANCE.bag_max_slots)
	inventory_changed.emit()
	return true


## Which ready set an item can go in: the seeds to plant, the combat set or the build set, or
## none. Tools, holy water, crops and materials are just carried: farm jobs say what's used.
func set_for(item: StringName) -> Array[StringName]:
	if item == &"sword" or item == &"bow":
		return combat_set
	if String(item).begins_with("seed_"):
		return plant_set
	if String(item).begins_with("build_"):
		return build_set
	var none: Array[StringName] = []
	return none


func job_on(job: StringName) -> bool:
	return not GameState.carry_mode or _jobs_for(job).has(job)


## Farm or build jobs: switches a job on or off.
func toggle_job(job: StringName) -> void:
	var jobs := _jobs_for(job)
	if jobs.has(job):
		jobs.erase(job)
	else:
		jobs.append(job)
	inventory_changed.emit()


func _jobs_for(job: StringName) -> Array[StringName]:
	return build_jobs if BUILD_JOBS.has(job) else farm_jobs


func can_set(item: StringName) -> bool:
	return item in [&"sword", &"bow"] or String(item).begins_with("seed_") or String(item).begins_with("build_")


## Moves an item one place up its set, so it's used sooner.
func move_sooner(item: StringName) -> void:
	var ready := set_for(item)
	var at := ready.find(item)
	if at <= 0:
		return
	ready[at] = ready[at - 1]
	ready[at - 1] = item
	inventory_changed.emit()


## Moves an item to the front of its set, so it's used next.
func to_front(item: StringName) -> void:
	var ready := set_for(item)
	ready.erase(item)
	ready.push_front(item)
	inventory_changed.emit()


## Adds a carried item to the end of its set, or takes it out if it's there. Returns false if
## the item can't go in a set.
func toggle_in_set(item: StringName) -> bool:
	if not can_set(item):
		return false
	var ready := set_for(item)
	if ready.has(item):
		ready.erase(item)
	elif carried(item) > 0:
		ready.append(item)
	else:
		return false
	inventory_changed.emit()
	return true


## The set's items that have something left, in order.
func ready_now(ready: Array[StringName]) -> Array[StringName]:
	return ready.filter(func(item: StringName) -> bool: return carried(item) > 0)


## Something new was gained: it goes in the bag if there's room, or else to storage.
func _carry(item: StringName, amount: int) -> void:
	if not GameState.carry_mode or amount <= 0:
		return
	if has_room_for(item):
		var new_kind: bool = bag.get(item, 0) <= 0
		# carried() is already counting the new amount, so take the bag's own count.
		bag[item] = bag.get(item, 0) + amount
		if new_kind:
			_join_set(item)
	else:
		GameState.notice.emit("Your bag is full. %s went to storage." % item_name(item))


## Storage controls: every game has a sword in the combat set and a lantern post in the build
## set, so both modes work from the start. The farm calls this as it loads, once the switch is
## read. Older saves get them too, once.
func give_starter_kit() -> void:
	if not GameState.carry_mode:
		return
	if not has_sword:
		has_sword = true
		_carry(&"sword", 1)
	if not starter_given:
		starter_given = true
		add_building(building_by_id(STARTER_BUILDING))
	inventory_changed.emit()


## A new kind in the bag joins its set, so the big button can use it at once. Seeds don't: the
## player picks which to plant, so nothing is planted that they meant to keep.
func _join_set(item: StringName) -> void:
	if not can_set(item) or set_for(item).has(item) or String(item).begins_with("seed_"):
		return
	# Arrows first, the sword once they run out: the bow goes to the front.
	if item == &"bow":
		combat_set.push_front(item)
		return
	set_for(item).append(item)


func _spend_carried(item: StringName, amount: int) -> void:
	if not bag.has(item):
		return
	bag[item] -= amount
	if bag[item] <= 0:
		bag.erase(item)


## After totals drop some other way (crafting), the bag can't hold more than is owned.
func _tidy_bag() -> void:
	for item in bag.keys():
		bag[item] = mini(bag[item], total(item))
		if bag[item] <= 0:
			bag.erase(item)


## Carry mode only uses what's carried.
func _has_carried(item: StringName, amount: int = 1) -> bool:
	return carried(item) >= amount


func seed_count(crop: CropData) -> int:
	return seeds.get(crop.id, 0)


func harvest_count(crop: CropData) -> int:
	return harvest.get(crop.id, 0)


## Crafting can leave a crop at a count of 0, so an entry alone doesn't mean there's a harvest.
func has_harvest() -> bool:
	return CROPS.any(func(crop: CropData) -> bool: return carried(crop_item(crop)) > 0)


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
	if not _has_carried(seed_item(crop)):
		return false
	seeds[crop.id] -= 1
	_spend_carried(seed_item(crop), 1)
	inventory_changed.emit()
	return true


func add_harvest(crop: CropData) -> void:
	harvest[crop.id] = harvest_count(crop) + 1
	_carry(crop_item(crop), 1)
	inventory_changed.emit()


## A blighted crop can't be sold, but it leaves a little money and a curse shard.
func take_blighted_crop() -> void:
	money += BALANCE.blighted_crop_money
	add_material(CURSE_SHARD, 1)
	GameState.notice.emit("+%d money, +1 %s" % [BALANCE.blighted_crop_money, CURSE_SHARD.display_name])


func add_material(material: MaterialData, amount: int) -> void:
	materials[material.id] = material_count(material) + amount
	_carry(material_item(material), amount)
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
		RecipeData.Result.BOW:
			return has_bow
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
			_carry(&"holy_water", recipe.result_amount)
		RecipeData.Result.BUILDING:
			add_building(recipe.building, recipe.result_amount)
		RecipeData.Result.PURIFYING_HOE:
			has_purifying_hoe = true
			hoe_uses_left = BALANCE.hoe_daily_uses
		RecipeData.Result.SWORD:
			has_sword = true
			_carry(&"sword", 1)
			if not combat_set.has(&"sword"):
				combat_set.append(&"sword")
		RecipeData.Result.STRONG_HOLY_WATER:
			strong_holy_water += recipe.result_amount
			_carry(&"strong_holy_water", recipe.result_amount)
		RecipeData.Result.BOW:
			has_bow = true
			_carry(&"bow", 1)
		RecipeData.Result.ARROWS:
			arrows += recipe.result_amount
			_carry(&"arrows", recipe.result_amount)
	_tidy_bag()
	inventory_changed.emit()
	return true


## Moves every harvested crop into the shipping box. With storage controls, only carried ones.
func ship_all() -> void:
	if has_harvest():
		Progress.record_action("ship")
	for crop in CROPS:
		var count := carried(crop_item(crop))
		if count <= 0:
			continue
		shipped[crop.id] = shipped.get(crop.id, 0) + count
		harvest[crop.id] -= count
		_spend_carried(crop_item(crop), count)
		if harvest[crop.id] <= 0:
			harvest.erase(crop.id)
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
	_carry(seed_item(crop), 1)
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
	_carry(&"holy_water", 1)
	holy_water_sold_today += 1
	inventory_changed.emit()
	return true


func add_building(building: BuildingData, amount: int = 1) -> void:
	buildings[building.id] = building_count(building) + amount
	_carry(building_item(building), amount)
	inventory_changed.emit()


## Removes one crafted building. Returns false if there are none left.
func use_building(building: BuildingData) -> bool:
	if not _has_carried(building_item(building)):
		return false
	buildings[building.id] -= 1
	_spend_carried(building_item(building), 1)
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
	if not _has_carried(&"strong_holy_water"):
		return false
	strong_holy_water -= 1
	_spend_carried(&"strong_holy_water", 1)
	inventory_changed.emit()
	return true


## Spends one carried arrow. Returns false if there are none.
func use_arrow() -> bool:
	if not _has_carried(&"arrows"):
		return false
	arrows -= 1
	_spend_carried(&"arrows", 1)
	inventory_changed.emit()
	return true


## Removes holy water. Returns false if there isn't enough (carried, with storage controls).
func use_holy_water(amount: int = 1) -> bool:
	if not _has_carried(&"holy_water", amount):
		return false
	holy_water -= amount
	_spend_carried(&"holy_water", amount)
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
			_carry(&"holy_water", find.amount)
			GameState.notice.emit("You dug up %d holy water!" % find.amount)
		BuriedFind.Kind.SEEDS:
			seeds[find.crop.id] = seed_count(find.crop) + find.amount
			_carry(seed_item(find.crop), find.amount)
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
	has_bow = false
	arrows = 0
	hoe_uses_left = 0
	can_water = BALANCE.can_capacity
	bag = START_BAG.duplicate()
	bag_slots = BALANCE.bag_start_slots
	farm_jobs = FARM_JOBS.duplicate()
	build_jobs = START_BUILD_JOBS.duplicate()
	plant_set = START_PLANT_SET.duplicate()
	combat_set = []
	build_set = []
	starter_given = false


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
	file.set_value("game", "bow", has_bow)
	file.set_value("game", "arrows", arrows)
	# A list of [item, count] pairs, because a saved dictionary comes back sorted, and the
	# order is the bag page's.
	var pairs: Array = []
	for item in bag:
		pairs.append([item, bag[item]])
	file.set_value("game", "bag", pairs)
	file.set_value("game", "bag_slots", bag_slots)
	file.set_value("game", "farm_jobs", farm_jobs)
	file.set_value("game", "build_jobs", build_jobs)
	file.set_value("game", "plant_set", plant_set)
	file.set_value("game", "combat_set", combat_set)
	file.set_value("game", "build_set", build_set)
	file.set_value("game", "starter_kit", starter_given)


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
	has_bow = file.get_value("game", "bow", has_bow)
	arrows = file.get_value("game", "arrows", arrows)
	# A bigger starting bag reaches older saves too.
	bag_slots = maxi(file.get_value("game", "bag_slots", bag_slots), BALANCE.bag_start_slots)
	starter_given = file.get_value("game", "starter_kit", false)
	if file.has_section_key("game", "bag"):
		bag.clear()
		for pair: Array in file.get_value("game", "bag"):
			bag[StringName(pair[0])] = int(pair[1])
	else:
		_fill_bag_for_old_save()
	farm_jobs.assign(file.get_value("game", "farm_jobs", FARM_JOBS))
	build_jobs.assign(file.get_value("game", "build_jobs", START_BUILD_JOBS))
	# A job tried and removed on 2026-11-08.
	build_jobs.erase(&"to_storage")
	if file.has_section_key("game", "combat_set"):
		combat_set.assign(file.get_value("game", "combat_set", []))
		build_set.assign(file.get_value("game", "build_set", []))
		plant_set.assign(file.get_value("game", "plant_set", []))
	else:
		# Everything carried that can go in a set does.
		combat_set.clear()
		build_set.clear()
		plant_set.clear()
		for item in bag:
			if can_set(item):
				set_for(item).append(item)
	# Saves from before kept seeds in a farming set: they move to the seeds to plant.
	for item: StringName in file.get_value("game", "farm_set", []):
		if String(item).begins_with("seed_") and not plant_set.has(item):
			plant_set.append(item)
	_refill_hoe()


## Saves from before the bag carry tools and holy water first, then whatever fits.
func _fill_bag_for_old_save() -> void:
	bag.clear()
	var order: Array[StringName] = OLD_SAVE_ORDER.duplicate()
	for item in all_items():
		if not order.has(item):
			order.append(item)
	for item in order:
		if bag.size() >= bag_slots:
			break
		if total(item) > 0:
			bag[item] = total(item)


func _refill_hoe() -> void:
	if has_purifying_hoe:
		hoe_uses_left = BALANCE.hoe_daily_uses
