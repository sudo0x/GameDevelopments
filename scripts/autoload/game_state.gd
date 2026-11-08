extends Node
## What the whole game shares that isn't owned items or progress: the balance numbers, help
## text for the controls in use, short notices, and requests to open things.
## Registered as the GameState autoload. See also Inventory, Progress and SaveGame.

## Something (the house door) asked to sleep. The HUD fades out and calls Progress.end_day().
signal sleep_requested
## The Action button reached the door. The sleep menu asks first.
signal sleep_asked
## Something (the shop stall) asked to open the shop. The shop menu opens.
signal shop_requested
## Something (the workbench) asked to open the crafting menu.
signal crafting_requested
## Something (the storage chest) asked to open storage.
signal storage_requested
## A short message for the player, such as what they just dug up.
signal notice(text: String)

const BALANCE: GameBalance = preload("res://data/balance.tres")

## True when the on-screen controls are showing, so help text can name them.
var touch_mode := false
## Storage controls (docs/28_...): a limited bag filled at the storage chest, Farm, Combat and
## Build modes, and objects used by tapping them. Always on for players. Tests pass
## --classic-controls to keep the classic controls, so the older tests still check the game's
## rules through them until those tests move over.
var carry_mode := false
var classic_forced := OS.get_cmdline_user_args().has("--classic-controls")


## Picks help text for the controls in use, so a phone never says "press Space".
func controls(keyboard: String, touch: String) -> String:
	return touch if touch_mode else keyboard


## The farm calls this as it loads.
func apply_controls_setting() -> void:
	carry_mode = not classic_forced


func request_storage() -> void:
	storage_requested.emit()


func ask_sleep() -> void:
	sleep_asked.emit()


func request_sleep() -> void:
	sleep_requested.emit()


func request_shop() -> void:
	shop_requested.emit()


func request_crafting() -> void:
	crafting_requested.emit()
