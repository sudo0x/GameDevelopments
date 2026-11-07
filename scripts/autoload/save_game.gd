extends Node
## Reads and writes the save file. Registered as the SaveGame autoload, after Inventory and
## Progress, because it loads into them when the game starts.
## Saves at the end of each day, so a game always resumes in the morning.
##
## Each part saves its own values: to add one, change save_to(), load_from() and reset() there.

const SAVE_PATH := "user://save.cfg"
## Saves are written here first, so a crash can't damage the real save.
const SAVE_TEMP_PATH := "user://save.tmp"
## Raise this when the save layout changes. Saves with another version are ignored.
const SAVE_VERSION := 1

## The farm's tilled cells and crops. Farm fills it at the end of the day and restores from it on start.
var farm_state: Dictionary = {}


func _ready() -> void:
	load_game()


func save_game() -> void:
	var file := ConfigFile.new()
	file.set_value("game", "version", SAVE_VERSION)
	Progress.save_to(file)
	Inventory.save_to(file)
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


## Keeps the new-game values if there's no save, or it can't be read.
func load_game() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK or file.get_value("game", "version", 0) != SAVE_VERSION:
		return
	Progress.load_from(file)
	Inventory.load_from(file)
	farm_state = file.get_value("game", "farm", farm_state)


## Erases the save and goes back to a new game.
func start_new_game() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(SAVE_TEMP_PATH)
	_reset()
	Progress.show_story = true


## Throws away everything since the last save (the morning), as if the game had been closed.
## Used when leaving to the title, so Continue starts from the save, not from half a day.
func discard_unsaved() -> void:
	_reset()
	load_game()


func _reset() -> void:
	Progress.reset()
	Inventory.reset()
	farm_state = {}
