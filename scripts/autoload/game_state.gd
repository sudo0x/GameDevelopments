extends Node
## Global game data: day, money and inventory. Registered as the GameState autoload.
## Saving and loading come in Layer 1 step 8.

signal inventory_changed
## Something (the house door) asked to sleep. The HUD fades out and calls end_day().
signal sleep_requested
## The day is over: crops grow, soil dries (and later: shipped crops are paid).
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


func seed_count(crop: CropData) -> int:
	return seeds.get(crop.id, 0)


func request_sleep() -> void:
	sleep_requested.emit()


func end_day() -> void:
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
