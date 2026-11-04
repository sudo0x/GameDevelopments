extends CanvasLayer
## Shows the day, money, inventory and the selected tool and seed, and fades to black when sleeping.

const FADE_SECONDS := 0.6

@export var player_path: NodePath

var _sleeping := false

@onready var player: Player = get_node(player_path)
@onready var tool_label: Label = $ToolLabel
@onready var day_label: Label = $DayLabel
@onready var money_label: Label = $MoneyLabel
@onready var inventory_label: Label = $InventoryLabel
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	player.tool_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh)
	GameState.day_started.connect(_refresh)
	GameState.sleep_requested.connect(_sleep)
	_refresh()


func _refresh() -> void:
	day_label.text = "Day %d" % GameState.day
	money_label.text = "Money: %d" % GameState.money
	inventory_label.text = _inventory_text()
	var text := "Tool: %s" % Player.TOOL_NAMES[player.tool]
	if player.tool == Player.Tool.SEEDS:
		var crop := player.selected_seed()
		text += "  |  %s seeds: %d  (Q / E to change)" % [crop.display_name, GameState.seed_count(crop)]
	if player.tool == Player.Tool.HOLY_WATER:
		text += ": %d" % GameState.holy_water
	tool_label.text = text


## One line per crop: harvested count, then seeds left. Then what's in the shipping box.
func _inventory_text() -> String:
	var lines: PackedStringArray = []
	for crop in GameState.CROPS:
		lines.append("%s: %d  (%d seeds)" % [crop.display_name, GameState.harvest_count(crop), GameState.seed_count(crop)])
	if not GameState.shipped.is_empty():
		lines.append("Shipping: %d overnight" % GameState.shipped_value())
	if GameState.holy_water > 0:
		lines.append("Holy water: %d" % GameState.holy_water)
	return "\n".join(lines)


## Fade out, end the day while the screen is black, fade back in.
func _sleep() -> void:
	if _sleeping:
		return
	_sleeping = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_SECONDS)
	tween.tween_callback(GameState.end_day)
	tween.tween_interval(0.3)
	tween.tween_property(fade, "color:a", 0.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: _sleeping = false)
