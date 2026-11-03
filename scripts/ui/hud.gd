extends CanvasLayer
## Shows the day and the selected tool and seed, and fades to black when sleeping.
## Grows into the full HUD (money, inventory) in step 6.

const FADE_SECONDS := 0.6

@export var player_path: NodePath

var _sleeping := false

@onready var player: Player = get_node(player_path)
@onready var tool_label: Label = $ToolLabel
@onready var day_label: Label = $DayLabel
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	player.tool_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh)
	GameState.day_started.connect(_refresh)
	GameState.sleep_requested.connect(_sleep)
	_refresh()


func _refresh() -> void:
	day_label.text = "Day %d" % GameState.day
	var text := "Tool: %s" % Player.TOOL_NAMES[player.tool]
	if player.tool == Player.Tool.SEEDS:
		var crop := player.selected_seed()
		text += "  |  %s seeds: %d  (Q / E to change)" % [crop.display_name, GameState.seed_count(crop)]
	tool_label.text = text


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
