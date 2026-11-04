extends CanvasLayer
## Shows the day, money, healing progress and the selected tool and seed,
## shows short notices, and fades to black when sleeping.

const FADE_SECONDS := 0.6
const NOTICE_SECONDS := 3.0

@export var player_path: NodePath
@export var farm_path: NodePath

var _sleeping := false
var _notice_tween: Tween

@onready var player: Player = get_node(player_path)
@onready var farm: Farm = get_node(farm_path)
@onready var tool_label: Label = $ToolLabel
@onready var day_label: Label = $DayLabel
@onready var money_label: Label = $MoneyLabel
@onready var status_label: Label = $StatusLabel
@onready var notice_label: Label = $NoticeLabel
@onready var crop_status_label: Label = $CropStatusLabel
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	player.tool_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh)
	GameState.day_started.connect(_refresh)
	GameState.sleep_requested.connect(_sleep)
	GameState.notice.connect(_show_notice)
	GameState.fainted.connect(_faint)
	farm.target_status_changed.connect(_show_crop_status)
	_refresh()


func _refresh() -> void:
	day_label.text = "Day %d" % GameState.day
	money_label.text = "Money: %d" % GameState.money
	status_label.text = _status_text()
	var text := "Tool: %s" % Player.TOOL_NAMES[player.tool]
	if player.tool == Player.Tool.SEEDS:
		var crop := player.selected_seed()
		text += "  |  %s seeds: %d  (Q / E to change)" % [crop.display_name, GameState.seed_count(crop)]
	if player.tool == Player.Tool.HOLY_WATER:
		text = _water_text()
	if player.tool == Player.Tool.BUILD:
		var building := player.selected_building()
		text += "  |  %s: %d  (Q / E to change)" % [building.display_name, GameState.building_count(building)]
	if player.tool == Player.Tool.SWORD and not GameState.has_sword:
		text += "  |  Craft one at the workbench"
	if player.tool == Player.Tool.HOE and GameState.has_purifying_hoe:
		text += "  |  Purify left today: %d" % GameState.hoe_uses_left
	tool_label.text = text


func _water_text() -> String:
	if player.strong_water:
		return "Tool: Strong holy water: %d  (Q / E to change)" % GameState.strong_holy_water
	var hint := "  (Q / E to change)" if GameState.strong_holy_water > 0 else ""
	return "Tool: Holy water: %d%s" % [GameState.holy_water, hint]


## Only what changes often is shown here. The full list is in the bag (key I).
func _status_text() -> String:
	var lines: PackedStringArray = []
	if GameState.holy_water > 0:
		lines.append("Holy water: %d" % GameState.holy_water)
	if GameState.strong_holy_water > 0:
		lines.append("Strong holy water: %d" % GameState.strong_holy_water)
	if not GameState.shipped.is_empty():
		lines.append("Shipping: %d overnight" % GameState.shipped_value())
	lines.append("Island healed: %.1f%%" % GameState.healed_percent)
	return "\n".join(lines)


func _show_crop_status(text: String) -> void:
	crop_status_label.text = text


func _show_notice(text: String) -> void:
	notice_label.text = text
	notice_label.modulate.a = 1.0
	if _notice_tween:
		_notice_tween.kill()
	_notice_tween = create_tween()
	_notice_tween.tween_interval(NOTICE_SECONDS)
	_notice_tween.tween_property(notice_label, "modulate:a", 0.0, 0.5)


## Fade out, end the day while the screen is black, fade back in.
func _sleep() -> void:
	_fade_to_next_day(GameState.end_day)


## Like sleeping, but the player wakes up at home.
func _faint(money_lost: int) -> void:
	_fade_to_next_day(func() -> void:
		# Home first, so the morning's creatures keep their distance from where the player wakes.
		player.return_home()
		GameState.end_day()
		GameState.notice.emit("You fainted and woke up at home. You lost %d money." % money_lost))


func _fade_to_next_day(while_black: Callable) -> void:
	if _sleeping:
		return
	_sleeping = true
	GameState.day_changing = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_SECONDS)
	tween.tween_callback(while_black)
	tween.tween_interval(0.3)
	tween.tween_property(fade, "color:a", 0.0, FADE_SECONDS)
	tween.tween_callback(func() -> void:
		_sleeping = false
		GameState.day_changing = false)
