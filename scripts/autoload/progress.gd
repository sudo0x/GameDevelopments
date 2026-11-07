extends Node
## How far the game has come: the day, the goal guide, today's health and the healed land.
## Registered as the Progress autoload.

## The day is over: crops grow, soil dries. Shipped crops are paid just before this.
signal day_ended
signal day_started
## The player finished something a goal in the guide may be waiting for.
signal guide_changed
signal hearts_changed
## The player ran out of hearts. The HUD fades out, ends the day and sends them home.
signal fainted(money_lost: int)

const BALANCE: GameBalance = preload("res://data/balance.tres")

## In guide_done, this means the lessons are over: saves from before the guide have it.
const GUIDE_FINISHED := "finished"

var day := 1
## Actions the player has done, for the goal guide. See GoalGuide.STEPS.
var guide_done: Array[String] = []
## Pages of the old book found so far. Saved, so pages stay if the curse takes land back.
var book_pages := BookPages.count_for(0.0)
## Set by a New Game, so the first morning opens with the story.
var show_story := false
## Health left today. Full every morning, and the game only saves in the morning, so it isn't saved.
var hearts: int = BALANCE.max_hearts
## True during the fade between days, when nothing can hurt the player.
var day_changing := false
## How much of the cursed land is healed, 0–100. Farm keeps it up to date; it isn't saved.
var healed_percent := 0.0


func end_day() -> void:
	Inventory.pay_shipped()
	record_action("sleep")
	day_ended.emit()
	day += 1
	Inventory.start_day()
	_refill_hearts()
	day_started.emit()
	SaveGame.save_game()


func record_action(action: String) -> void:
	if not guide_done.has(action):
		guide_done.append(action)
		guide_changed.emit()


## Also sends inventory_changed, because that's what makes the HUD redraw its numbers.
func set_healed_percent(percent: float) -> void:
	healed_percent = percent
	var pages := BookPages.count_for(percent)
	if pages > book_pages:
		book_pages = pages
		GameState.notice.emit("A page of the old book has cleared.")
	Inventory.inventory_changed.emit()


## Removes hearts, and faints at zero. Does nothing once the player has already fainted.
func take_damage(amount: int) -> void:
	if hearts <= 0:
		return
	hearts = maxi(hearts - amount, 0)
	hearts_changed.emit()
	if hearts == 0:
		fainted.emit(Inventory.lose_faint_money())


func reset() -> void:
	day = 1
	guide_done.clear()
	book_pages = BookPages.count_for(0.0)
	hearts = BALANCE.max_hearts
	healed_percent = 0.0
	day_changing = false


func save_to(file: ConfigFile) -> void:
	file.set_value("game", "day", day)
	file.set_value("game", "guide_done", guide_done)
	file.set_value("game", "book_pages", book_pages)


func load_from(file: ConfigFile) -> void:
	day = file.get_value("game", "day", day)
	guide_done.assign(file.get_value("game", "guide_done", [GUIDE_FINISHED]))
	book_pages = file.get_value("game", "book_pages", book_pages)


func _refill_hearts() -> void:
	hearts = BALANCE.max_hearts
	hearts_changed.emit()
