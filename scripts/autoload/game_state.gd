extends Node
## Global game data: day, money and inventory. Registered as the GameState autoload.
## Saves at the end of each day and loads on start, so a game always resumes in the morning.

signal inventory_changed
## Something (the house door) asked to sleep. The HUD fades out and calls end_day().
signal sleep_requested
## Something (the shop stall) asked to open the shop. The shop menu opens.
signal shop_requested
## Something (the workbench) asked to open the crafting menu.
signal crafting_requested
## A short message for the player, such as what they just dug up.
signal notice(text: String)
signal hearts_changed
## The player ran out of hearts. The HUD fades out, ends the day and sends them home.
signal fainted(money_lost: int)
## The day is over: crops grow, soil dries. Shipped crops are paid just before this.
signal day_ended
signal day_started

const BALANCE: GameBalance = preload("res://data/balance.tres")

const START_SEEDS: Dictionary[StringName, int] = {&"radish": 10, &"carrot": 5, &"pumpkin": 3}

const SAVE_PATH := "user://save.cfg"
## Saves are written here first, so a crash can't damage the real save.
const SAVE_TEMP_PATH := "user://save.tmp"
## Raise this when the save layout changes. Saves with another version are ignored.
const SAVE_VERSION := 1

const CROPS: Array[CropData] = [
	preload("res://data/crops/radish.tres"),
	preload("res://data/crops/carrot.tres"),
	preload("res://data/crops/pumpkin.tres"),
]

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

## Loaded when the game starts, not preloaded: the shipping box and workbench scripts use
## GameState, so preloading them here would be a loop and leave them half loaded.
## Treat it as a constant.
var BUILDINGS: Array[BuildingData] = [
	load("res://data/buildings/lantern_post.tres"),
	load("res://data/buildings/fence.tres"),
	load("res://data/buildings/well.tres"),
	load("res://data/buildings/shipping_box.tres"),
	load("res://data/buildings/workbench.tres"),
	load("res://data/buildings/old_lantern_post.tres"),
]

var day := 1
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
## The crafted upgrade: the hoe also heals single cursed tiles, a few times a day.
var has_purifying_hoe := false
## Like holy water, but it heals a bigger patch.
var strong_holy_water := 0
var has_sword := false
## Purifying uses left today. Full every morning, so only owning the hoe is saved.
var hoe_uses_left := 0
## Health left today. Full every morning, and the game only saves in the morning, so it isn't saved.
var hearts: int = BALANCE.max_hearts
## True when the on-screen controls are showing, so help text can name them.
var touch_mode := false
## True during the fade between days, when nothing can hurt the player.
var day_changing := false
## How much of the cursed land is healed, 0–100. Farm keeps it up to date; it isn't saved.
var healed_percent := 0.0
## The farm's tilled cells and crops. Farm fills it at the end of the day and restores from it on start.
var farm_state: Dictionary = {}


func _ready() -> void:
	load_game()


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


## Picks help text for the controls in use, so a phone never says "press Space".
func controls(keyboard: String, touch: String) -> String:
	return touch if touch_mode else keyboard


func request_sleep() -> void:
	sleep_requested.emit()


func request_shop() -> void:
	shop_requested.emit()


func request_crafting() -> void:
	crafting_requested.emit()


func end_day() -> void:
	_pay_shipped()
	day_ended.emit()
	day += 1
	_refill_hoe()
	_refill_hearts()
	day_started.emit()
	save_game()


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
	for id in harvest:
		shipped[id] = shipped.get(id, 0) + harvest[id]
	harvest.clear()
	inventory_changed.emit()


## Buys one seed. Returns false if there isn't enough money.
func buy_seed(crop: CropData) -> bool:
	if money < crop.seed_price:
		return false
	money -= crop.seed_price
	seeds[crop.id] = seed_count(crop) + 1
	inventory_changed.emit()
	return true


## The shipping box isn't saved: it's always empty here, because end_day() pays it first.
func save_game() -> void:
	var file := ConfigFile.new()
	file.set_value("game", "version", SAVE_VERSION)
	file.set_value("game", "day", day)
	file.set_value("game", "money", money)
	file.set_value("game", "seeds", seeds)
	file.set_value("game", "harvest", harvest)
	file.set_value("game", "materials", materials)
	file.set_value("game", "buildings", buildings)
	file.set_value("game", "holy_water", holy_water)
	file.set_value("game", "strong_holy_water", strong_holy_water)
	file.set_value("game", "purifying_hoe", has_purifying_hoe)
	file.set_value("game", "sword", has_sword)
	file.set_value("game", "farm", farm_state)
	var error := file.save(SAVE_TEMP_PATH)
	if error == OK:
		error = DirAccess.rename_absolute(SAVE_TEMP_PATH, SAVE_PATH)
	if error != OK:
		push_error("Couldn't save the game: %s" % error_string(error))


## Whether there's a save that load_game() could use.
func has_save() -> bool:
	var file := ConfigFile.new()
	return file.load(SAVE_PATH) == OK and file.get_value("game", "version", 0) == SAVE_VERSION


## Erases the save and goes back to a new game. Every value that's saved must be reset here.
func start_new_game() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SAVE_TEMP_PATH)
	_reset()


## Throws away everything since the last save (the morning), as if the game had been closed.
## Used when leaving to the title, so Continue starts from the save, not from half a day.
func discard_unsaved() -> void:
	_reset()
	load_game()


func _reset() -> void:
	day = 1
	money = 0
	seeds = START_SEEDS.duplicate()
	harvest.clear()
	materials.clear()
	buildings.clear()
	shipped.clear()
	holy_water = BALANCE.start_holy_water
	strong_holy_water = 0
	has_purifying_hoe = false
	has_sword = false
	hoe_uses_left = 0
	hearts = BALANCE.max_hearts
	healed_percent = 0.0
	day_changing = false
	farm_state = {}


## Keeps the new-game values if there's no save, or it can't be read.
func load_game() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK or file.get_value("game", "version", 0) != SAVE_VERSION:
		return
	day = file.get_value("game", "day", day)
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
	farm_state = file.get_value("game", "farm", farm_state)


## Buys one holy water. Returns false if there isn't enough money.
func buy_holy_water() -> bool:
	if money < BALANCE.holy_water_price:
		return false
	money -= BALANCE.holy_water_price
	holy_water += 1
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


func set_healed_percent(percent: float) -> void:
	healed_percent = percent
	inventory_changed.emit()


## Gives the player what was buried.
func give_find(find: BuriedFind) -> void:
	match find.kind:
		BuriedFind.Kind.MONEY:
			money += find.amount
			notice.emit("You dug up %d money!" % find.amount)
		BuriedFind.Kind.HOLY_WATER:
			holy_water += find.amount
			notice.emit("You dug up %d holy water!" % find.amount)
		BuriedFind.Kind.SEEDS:
			seeds[find.crop.id] = seed_count(find.crop) + find.amount
			notice.emit("You dug up %d %s seeds!" % [find.amount, find.crop.display_name.to_lower()])
	inventory_changed.emit()


## Removes hearts, and faints at zero. Does nothing once the player has already fainted.
func take_damage(amount: int) -> void:
	if hearts <= 0:
		return
	hearts = maxi(hearts - amount, 0)
	hearts_changed.emit()
	if hearts == 0:
		_faint()


func _faint() -> void:
	var lost: int = money * BALANCE.faint_money_percent / 100
	money -= lost
	inventory_changed.emit()
	fainted.emit(lost)


func _refill_hearts() -> void:
	hearts = BALANCE.max_hearts
	hearts_changed.emit()


func _refill_hoe() -> void:
	if has_purifying_hoe:
		hoe_uses_left = BALANCE.hoe_daily_uses


func _pay_shipped() -> void:
	money += shipped_value()
	shipped.clear()
	inventory_changed.emit()
