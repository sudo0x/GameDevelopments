extends CanvasLayer
## Shows the day, money, healing progress and the selected tool and seed,
## shows short notices, and fades to black when sleeping.

const FADE_SECONDS := 0.6
const NOTICE_SECONDS := 3.0
## While more notices wait, each shows this long, so a burst doesn't take ages.
const QUEUED_NOTICE_SECONDS := 1.5
const NOTICE_FADE_SECONDS := 0.5
## Older waiting notices are dropped past this, so the queue never lags far behind play.
const MAX_WAITING_NOTICES := 4
## A new goal shows this long, then fades. The Tasks menu keeps it after that.
const GOAL_SECONDS := 6.0
const GOAL_WIDTH := 340.0
const GOAL_COLOR := Color(1.0, 0.9, 0.6)
const GOAL_OUTLINE_COLOR := Color(0.1, 0.07, 0.08)
const GOAL_OUTLINE_SIZE := 6
const TOOL_LINE_HEIGHT := 24.0
## Phones keep the Tasks button here, so the goal starts to its right.
const GOAL_TOUCH_INDENT := 52.0

@export var player_path: NodePath
@export var farm_path: NodePath

var _sleeping := false
var _pick_menu := PickMenu.new()
var _book_menu := BookMenu.new()
var _tasks_menu := TasksMenu.new()
var _goal_line := Label.new()
var _goal_fade: Tween
## Notices waiting their turn, oldest first, and how long the one showing has left.
var _waiting_notices: Array[String] = []
var _notice_left := 0.0

@onready var player: Player = get_node(player_path)
@onready var farm: Farm = get_node(farm_path)
@onready var tool_label: Label = $ToolLabel
@onready var day_label: Label = $DayLabel
@onready var money_label: Label = $MoneyRow/MoneyLabel
@onready var status_label: Label = $StatusLabel
@onready var notice_label: Label = $NoticeLabel
@onready var crop_status_label: Label = $CropStatusLabel
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	player.tool_changed.connect(_refresh)
	Inventory.inventory_changed.connect(_refresh)
	Progress.day_started.connect(_refresh)
	GameState.sleep_requested.connect(_sleep)
	GameState.notice.connect(_show_notice)
	Progress.fainted.connect(_faint)
	farm.target_status_changed.connect(_show_crop_status)
	farm.action_changed.connect($TouchControls.show_action)
	farm.heal_changed.connect($TouchControls.show_heal)
	farm.water_choice_needed.connect(_ask_water)
	player.seed_menu_pressed.connect(_ask_seed)
	$BagMenu.build_pressed.connect(_ask_building)
	$BagMenu.book_pressed.connect(_book_menu.open)
	farm.mover.is_free_spot = $TouchControls.is_free_spot
	_add_goal_guide()
	_add_menus()
	_refresh()


func _add_goal_guide() -> void:
	_goal_line.name = "GoalLine"
	_goal_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal_line.custom_minimum_size.x = GOAL_WIDTH
	_goal_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# It sits over trees and grass, so it needs more help to read than other text.
	_goal_line.add_theme_color_override("font_color", GOAL_COLOR)
	_goal_line.add_theme_color_override("font_outline_color", GOAL_OUTLINE_COLOR)
	_goal_line.add_theme_constant_override("outline_size", GOAL_OUTLINE_SIZE)
	_goal_line.hide()
	add_child(_goal_line)
	move_child(_goal_line, tool_label.get_index() + 1)
	var guide := GoalGuide.new()
	guide.name = "GoalGuide"
	guide.announced.connect(_show_goal)
	add_child(guide)
	_tasks_menu.setup(guide)


## Under the tool text for a moment, so the screen stays clear the rest of the time.
func _show_goal(goal: String) -> void:
	_goal_line.text = goal
	var indent := GOAL_TOUCH_INDENT if GameState.touch_mode else 0.0
	_goal_line.position = tool_label.position + Vector2(indent, TOOL_LINE_HEIGHT)
	_goal_line.modulate.a = 1.0
	_goal_line.show()
	if _goal_fade:
		_goal_fade.kill()
	_goal_fade = create_tween()
	_goal_fade.tween_interval(GOAL_SECONDS)
	_goal_fade.tween_property(_goal_line, "modulate:a", 0.0, NOTICE_FADE_SECONDS)
	_goal_fade.tween_callback(_goal_line.hide)


## With the other menus: under the fade, and over everything else.
func _add_menus() -> void:
	for menu: GameMenu in [SleepMenu.new(), _pick_menu, _book_menu, _tasks_menu]:
		add_child(menu)
		move_child(menu, fade.get_index())


func _ask_seed() -> void:
	var choices: Array[Dictionary] = []
	for i in Inventory.CROPS.size():
		var crop := Inventory.CROPS[i]
		var count := Inventory.seed_count(crop)
		choices.append({
			"text": "%s seeds: %d" % [crop.display_name, count],
			"icon": crop.seed_icon,
			"dim": count == 0,
			"pick": player.select_seed.bind(i),
		})
	_pick_menu.ask("Which seed?", choices)


## Only what the player owns, so nothing in the list is a dead end.
func _ask_building() -> void:
	var choices: Array[Dictionary] = []
	for i in Inventory.BUILDINGS.size():
		var building := Inventory.BUILDINGS[i]
		var count := Inventory.building_count(building)
		if count > 0:
			choices.append({
				"text": "%s: %d" % [building.display_name, count],
				"icon": building.preview_texture,
				"pick": player.start_building.bind(i),
			})
	if choices.is_empty():
		GameState.notice.emit("Nothing to build. Craft something at the workbench.")
	else:
		_pick_menu.ask("What to build?", choices)


func _ask_water() -> void:
	var choices: Array[Dictionary] = [
		{"text": "Holy water: %d" % Inventory.holy_water, "icon": GameMenu.HOLY_WATER_ICON, "pick": farm.heal_with.bind(false)},
		{"text": "Strong water: %d" % Inventory.strong_holy_water, "icon": GameMenu.STRONG_WATER_ICON, "pick": farm.heal_with.bind(true)},
	]
	_pick_menu.ask("Which water?", choices)


func _refresh() -> void:
	day_label.text = "Day %d" % Progress.day
	money_label.text = str(Inventory.money)
	status_label.text = _status_text()
	if GameState.touch_mode:
		tool_label.text = _touch_tool_text()
		return
	var text := "Tool: %s" % Player.TOOL_NAMES[player.tool]
	if player.tool == Player.Tool.SEEDS:
		var crop := player.selected_seed()
		text += "  |  %s seeds: %d  %s" % [crop.display_name, Inventory.seed_count(crop), _change_hint()]
	if player.tool == Player.Tool.HOLY_WATER:
		text = _water_text()
	if player.tool == Player.Tool.BUILD:
		var building := player.selected_building()
		text += "  |  %s: %d  %s" % [building.display_name, Inventory.building_count(building), _change_hint()]
	if player.tool == Player.Tool.SWORD and not Inventory.has_sword:
		text += "  |  Craft one at the workbench"
	if player.tool == Player.Tool.HOE and Inventory.has_purifying_hoe:
		text += "  |  Purify left today: %d" % Inventory.hoe_uses_left
	tool_label.text = text


## Phones have no tools to show, so this line holds what the buttons can't.
func _touch_tool_text() -> String:
	if player.tool == Player.Tool.BUILD:
		var building := player.selected_building()
		return "Building: %s, %d left" % [building.display_name, Inventory.building_count(building)]
	var crop := player.selected_seed()
	var text := "%s seeds: %d" % [crop.display_name, Inventory.seed_count(crop)]
	if Inventory.has_purifying_hoe:
		text += "  |  Purify left today: %d" % Inventory.hoe_uses_left
	return text


## Only computers reach this: phones show _touch_tool_text() instead.
func _change_hint() -> String:
	return "(Q / E to change)"


func _water_text() -> String:
	if player.strong_water:
		return "Tool: Strong holy water: %d  %s" % [Inventory.strong_holy_water, _change_hint()]
	var hint := "  " + _change_hint() if Inventory.strong_holy_water > 0 else ""
	return "Tool: Holy water: %d%s" % [Inventory.holy_water, hint]


## Only what changes often is shown here. The full list is in the bag (key I).
func _status_text() -> String:
	var lines: PackedStringArray = []
	if Inventory.holy_water > 0:
		lines.append("Holy water: %d" % Inventory.holy_water)
	if Inventory.strong_holy_water > 0:
		lines.append("Strong holy water: %d" % Inventory.strong_holy_water)
	if not Inventory.shipped.is_empty():
		lines.append("Shipping: %d overnight" % Inventory.shipped_value())
	# Only once it matters, to keep the corner calm.
	if Inventory.can_water < GameState.BALANCE.can_capacity:
		lines.append("Water: %d of %d" % [Inventory.can_water, GameState.BALANCE.can_capacity])
	lines.append("Island healed: %.1f%%" % Progress.healed_percent)
	return "\n".join(lines)


func _show_crop_status(text: String) -> void:
	crop_status_label.text = text


## The notice showing now, or the last one shown (faded out).
func latest_notice() -> String:
	return notice_label.text


## Notices take turns on one line, so none replaces another before it can be read.
func _show_notice(text: String) -> void:
	if _notice_left > 0.0 and text == notice_label.text:
		_notice_left = maxf(_notice_left, NOTICE_SECONDS if _waiting_notices.is_empty() else QUEUED_NOTICE_SECONDS)
		return
	if _waiting_notices.has(text):
		return
	if _notice_left <= 0.0:
		_display_notice(text)
		return
	_waiting_notices.append(text)
	if _waiting_notices.size() > MAX_WAITING_NOTICES:
		_waiting_notices.pop_front()
	_notice_left = minf(_notice_left, QUEUED_NOTICE_SECONDS)


func _display_notice(text: String) -> void:
	notice_label.text = text
	notice_label.modulate.a = 1.0
	_notice_left = NOTICE_SECONDS if _waiting_notices.is_empty() else QUEUED_NOTICE_SECONDS


func _process(delta: float) -> void:
	if _notice_left <= 0.0:
		return
	_notice_left -= delta
	if _notice_left <= 0.0 and not _waiting_notices.is_empty():
		_display_notice(_waiting_notices.pop_front())
	elif _waiting_notices.is_empty():
		# Only the last one fades: the next replaces it straight away otherwise.
		notice_label.modulate.a = clampf(_notice_left / NOTICE_FADE_SECONDS, 0.0, 1.0)


## Fade out, end the day while the screen is black, fade back in.
func _sleep() -> void:
	_fade_to_next_day(Progress.end_day)


## Like sleeping, but the player wakes up at home.
func _faint(money_lost: int) -> void:
	_fade_to_next_day(func() -> void:
		# Home first, so the morning's creatures keep their distance from where the player wakes.
		player.return_home()
		Progress.end_day()
		GameState.notice.emit("You fainted and woke up at home. You lost %d money." % money_lost))


func _fade_to_next_day(while_black: Callable) -> void:
	if _sleeping:
		return
	_sleeping = true
	Progress.day_changing = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_SECONDS)
	tween.tween_callback(while_black)
	tween.tween_interval(0.3)
	tween.tween_property(fade, "color:a", 0.0, FADE_SECONDS)
	tween.tween_callback(func() -> void:
		_sleeping = false
		Progress.day_changing = false)
