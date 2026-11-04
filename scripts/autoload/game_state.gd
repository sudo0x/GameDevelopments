extends Node
## Global game data: day, money and inventory. Registered as the GameState autoload.
## Saving and loading come in Layer 1 step 8.

signal inventory_changed
## Something (the house door) asked to sleep. The HUD fades out and calls end_day().
signal sleep_requested
## Something (the shop stall) asked to open the shop. The shop menu opens.
signal shop_requested
## The day is over: crops grow, soil dries. Shipped crops are paid just before this.
signal day_ended
signal day_started

const CROPS: Array[CropData] = [
	preload("res://data/crops/radish.tres"),
	preload("res://data/crops/carrot.tres"),
	preload("res://data/crops/pumpkin.tres"),
]

var day := 1
var money := 0
## Seed counts by crop id.
var seeds: Dictionary[StringName, int] = {&"radish": 10, &"carrot": 5, &"pumpkin": 3}
## Harvested crop counts by crop id.
var harvest: Dictionary[StringName, int] = {}
## Crops in the shipping box by crop id, paid when the day ends.
var shipped: Dictionary[StringName, int] = {}


func seed_count(crop: CropData) -> int:
	return seeds.get(crop.id, 0)


func harvest_count(crop: CropData) -> int:
	return harvest.get(crop.id, 0)


## What everything in the shipping box will earn overnight.
func shipped_value() -> int:
	var total := 0
	for crop in CROPS:
		total += shipped.get(crop.id, 0) * crop.sell_price
	return total


func request_sleep() -> void:
	sleep_requested.emit()


func request_shop() -> void:
	shop_requested.emit()


func end_day() -> void:
	_pay_shipped()
	day_ended.emit()
	day += 1
	day_started.emit()


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


func _pay_shipped() -> void:
	money += shipped_value()
	shipped.clear()
	inventory_changed.emit()
