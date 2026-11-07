extends Node
## What the whole game shares that isn't owned items or progress: the balance numbers, help
## text for the controls in use, short notices, and requests to open things.
## Registered as the GameState autoload. See also Inventory, Progress and SaveGame.

## Something (the house door) asked to sleep. The HUD fades out and calls Progress.end_day().
signal sleep_requested
## Something (the shop stall) asked to open the shop. The shop menu opens.
signal shop_requested
## Something (the workbench) asked to open the crafting menu.
signal crafting_requested
## A short message for the player, such as what they just dug up.
signal notice(text: String)

const BALANCE: GameBalance = preload("res://data/balance.tres")

## True when the on-screen controls are showing, so help text can name them.
var touch_mode := false


## Picks help text for the controls in use, so a phone never says "press Space".
func controls(keyboard: String, touch: String) -> String:
	return touch if touch_mode else keyboard


func request_sleep() -> void:
	sleep_requested.emit()


func request_shop() -> void:
	shop_requested.emit()


func request_crafting() -> void:
	crafting_requested.emit()
