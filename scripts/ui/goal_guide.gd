class_name GoalGuide
extends Label
## Teaches the game by doing: one goal at a time under the tool text, ticked off by playing, then
## the long goal. A New Game opens with a short story panel. Each row is the action that finishes
## the goal (see GameState.record_action), then its text for keyboards and for touch screens.

const STEPS: Array[Array] = [
	["till", "Goal: press 1, then Space to till the soil.", "Goal: tap the hoe, then Use to till the soil."],
	["plant", "Goal: press 3, then Space to plant a seed in the soil.", "Goal: tap the seeds, then Use to plant in the soil."],
	["water", "Goal: press 2, then Space to water your seed.", "Goal: tap the watering can, then Use to water your seed."],
	["sleep", "Goal: go to your house door and press F to sleep.", "Goal: go to your house door and tap ! to sleep."],
	["heal", "Goal: stand by the curse. Press 5, then Space to heal it.", "Goal: stand by the curse. Tap the holy water, then Use."],
	["harvest", "Goal: water and sleep until it's ripe, then press 4 and Space.", "Goal: water and sleep until it's ripe, then tap the glove and Use."],
	["ship", "Goal: press F at the shipping box to sell your harvest.", "Goal: tap ! at the shipping box to sell your harvest."],
	["plant_ward", "Goal: buy a wardthorn seed at the stall. Plant it by the curse to guard your land.", "Goal: buy a wardthorn seed at the stall. Plant it by the curse to guard your land."],
]
const SHRINE_GOAL := "Long goal: heal a path east and restore the old shrine."
const LAST_GOAL := "Long goal: keep healing the island."
const STORY := "A curse is killing this island. Your farm is the last green land.\n\nGrow crops, earn holy water, and heal the island, one tile at a time."
const TEXT_COLOR := Color(1.0, 0.9, 0.6)
const WIDTH := 340.0
const OUTLINE_COLOR := Color(0.1, 0.07, 0.08)
const OUTLINE_SIZE := 6
const STORY_MARGIN := 16
const TOOL_LINE_HEIGHT := 24.0
const STORY_WIDTH := 400.0
const PANEL_STYLE := preload("res://data/ui/menu_panel.tres")

var _tool_label: Label
var _story: PanelContainer


func setup(tool_label: Label) -> void:
	_tool_label = tool_label


func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	custom_minimum_size.x = WIDTH
	size.x = WIDTH
	modulate = TEXT_COLOR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Goals sit over trees and grass, so they need more help to read than other text.
	add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	add_theme_constant_override("outline_size", OUTLINE_SIZE)
	GameState.guide_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh)
	GameState.day_started.connect(_refresh)
	_refresh()
	if GameState.show_story:
		GameState.show_story = false
		_open_story.call_deferred()


## The goal to show now.
func current_text() -> String:
	if not GameState.guide_done.has(GameState.GUIDE_FINISHED):
		for step in STEPS:
			if not GameState.guide_done.has(step[0]):
				return GameState.controls(step[1], step[2])
	return LAST_GOAL if GameState.farm_state.get("shrine", false) else SHRINE_GOAL


func _refresh() -> void:
	text = current_text()
	# Phones move the tool text up, and this follows it.
	position = Vector2(_tool_label.position.x, _tool_label.position.y + TOOL_LINE_HEIGHT)


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
