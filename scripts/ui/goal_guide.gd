class_name GoalGuide
extends Node
## Teaches the game by doing: one goal at a time, ticked off by playing, then the long goal. Goals
## stay off the screen, so a new one shows for a moment and TasksMenu lists them all. A New
## Game opens with a short story panel. Each row is the action that finishes the goal (see
## Progress.record_action), its text for keyboards and for touch screens, and its name once done.

const STEPS: Array[Array] = [
	["till", "Goal: face the grass and press R to till it.", "Goal: face the grass and tap the big button to till it.", "Till the soil"],
	["plant", "Goal: press R again to plant a seed.", "Goal: tap the big button again to plant a seed.", "Plant a seed"],
	["water", "Goal: press R again to water your seed.", "Goal: tap the big button again to water your seed.", "Water your seed"],
	["sleep", "Goal: go to your house door and press F to sleep.", "Goal: go to your house door and tap the big button to sleep.", "Sleep"],
	["heal", "Goal: stand by the curse. Press 5, then Space to heal it.", "Goal: stand by the curse and tap the bottle to heal it.", "Heal the curse"],
	["harvest", "Goal: water and sleep until it's ripe, then press R.", "Goal: water and sleep until it's ripe, then tap the big button.", "Harvest a crop"],
	["ship", "Goal: press R at the shipping box to sell your harvest.", "Goal: tap the big button at the shipping box to sell your harvest.", "Sell your harvest"],
	["plant_ward", "Goal: buy a wardthorn seed at the stall, pick it with Q or E, and plant it by the curse.", "Goal: buy a wardthorn seed at the stall, pick it with the seed bag, and plant it by the curse.", "Plant a wardthorn"],
]
## Storage controls (docs/28_...) do some lessons differently: objects are tapped, holy water
## heals from the farming set, and seeds are picked on the bag page. Keyboard text, then touch.
const CARRY_TEXT: Dictionary[String, Array] = {
	"sleep": ["Goal: go to your house door and click it, or press F, to sleep.", "Goal: go to your house door and tap it to sleep."],
	"heal": ["Goal: face a cursed tile and press R. Holy water heals it.", "Goal: face a cursed tile and tap the big button. Holy water heals it."],
	"ship": ["Goal: click the shipping box, or press F, to sell your harvest.", "Goal: tap the shipping box to sell your harvest."],
	"plant_ward": ["Goal: buy a wardthorn seed at the stall, add it to the seeds to plant on the Modes page (I), and plant it by the curse.", "Goal: buy a wardthorn seed at the stall, add it to the seeds to plant on the Modes page (Bag button), and plant it by the curse."],
}
const SHRINE_GOAL := "Long goal: heal a path east and restore the old shrine."
const LAST_GOAL := "Long goal: keep healing the island."
## A new goal to show for a moment. The HUD draws it.
signal announced(goal: String)

const STORY := "A curse is killing this island. Your farm is the last green land.\n\nGrow crops, earn holy water, and heal the island, one tile at a time."
const STORY_MARGIN := 16
const STORY_WIDTH := 400.0
const PANEL_STYLE := preload("res://data/ui/menu_panel.tres")

## The goal right now.
var text := ""

var _story: PanelContainer
## Which goal was last shown, so rewording it for touch screens isn't news.
var _shown_goal := ""


func _ready() -> void:
	Progress.guide_changed.connect(_refresh)
	Inventory.inventory_changed.connect(_refresh)
	Progress.day_started.connect(_refresh)
	text = current_text()
	_shown_goal = _goal_id()
	if Progress.show_story:
		Progress.show_story = false
		_open_story.call_deferred()
	elif not lesson_text().is_empty():
		_announce.call_deferred()


## The goal to show now.
func current_text() -> String:
	var step := _next_step()
	if not step.is_empty():
		return _step_text(step)
	return LAST_GOAL if SaveGame.farm_state.get("shrine", false) else SHRINE_GOAL


## The lesson to do now without its "Goal:", or empty once they're over.
func lesson_text() -> String:
	var step := _next_step()
	return _sentence(_step_text(step).trim_prefix("Goal: ")) if not step.is_empty() else ""


func _step_text(step: Array) -> String:
	if GameState.carry_mode and CARRY_TEXT.has(step[0]):
		return GameState.controls(CARRY_TEXT[step[0]][0], CARRY_TEXT[step[0]][1])
	return GameState.controls(step[1], step[2])


func long_goal_text() -> String:
	var goal := LAST_GOAL if SaveGame.farm_state.get("shrine", false) else SHRINE_GOAL
	return _sentence(goal.trim_prefix("Long goal: "))


## Names of the lessons finished so far. Older saves skipped them, so they have none.
func done_names() -> PackedStringArray:
	var names: PackedStringArray = []
	for step in STEPS:
		if Progress.guide_done.has(step[0]):
			names.append(step[3])
	return names


func _sentence(text_part: String) -> String:
	return text_part.left(1).to_upper() + text_part.substr(1)


func _next_step() -> Array:
	if not Progress.guide_done.has(Progress.GUIDE_FINISHED):
		for step in STEPS:
			if not Progress.guide_done.has(step[0]):
				return step
	return []


func _goal_id() -> String:
	var step := _next_step()
	return step[0] if not step.is_empty() else current_text()


func _refresh() -> void:
	text = current_text()
	if _goal_id() != _shown_goal:
		_shown_goal = _goal_id()
		_announce()


func _announce() -> void:
	announced.emit(text)


func _open_story() -> void:
	_story = PanelContainer.new()
	_story.process_mode = Node.PROCESS_MODE_ALWAYS
	_story.add_theme_stylebox_override("panel", PANEL_STYLE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	var words := Label.new()
	words.text = STORY
	words.custom_minimum_size.x = STORY_WIDTH
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var start := Button.new()
	start.text = "Start farming"
	start.custom_minimum_size = Vector2(160, GameMenu.BUTTON_SIZE.y)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(_close_story)
	box.add_child(words)
	box.add_child(start)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, STORY_MARGIN)
	margin.add_child(box)
	_story.add_child(margin)
	get_parent().add_child(_story)
	_story.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	_story.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_story.grow_vertical = Control.GROW_DIRECTION_BOTH
	get_tree().paused = true
	start.grab_focus()


func _close_story() -> void:
	_story.queue_free()
	_story = null
	get_tree().paused = false
	_announce()
