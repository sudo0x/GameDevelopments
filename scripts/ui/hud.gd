extends CanvasLayer
## Shows the day, money, inventory, healing progress and the selected tool and seed,
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
@onready var inventory_label: Label = $InventoryLabel
@onready var notice_label: Label = $NoticeLabel
@onready var crop_status_label: Label = $CropStatusLabel
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	player.tool_changed.connect(_refresh)
	GameState.inventory_changed.connect(_refresh)
	GameState.day_started.connect(_refresh)
	GameState.sleep_requested.connect(_sleep)
	GameState.notice.connect(_show_notice)
	farm.target_status_changed.connect(_show_crop_status)
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
	if _sleeping:
		return
	_sleeping = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_SECONDS)
	tween.tween_callback(GameState.end_day)
	tween.tween_interval(0.3)
	tween.tween_property(fade, "color:a", 0.0, FADE_SECONDS)
	tween.tween_callback(func() -> void: _sleeping = false)
