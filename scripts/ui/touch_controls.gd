class_name TouchControls
extends Node2D
## On-screen controls for phones. Every button presses a normal input action, so game code
## works the same with touch and keyboard. Built from the tables below.
## TouchScreenButton is used because, unlike Button, it works while another finger is down.

const BUTTON_TEXTURE := preload("res://assets/ui/touch_button.png")
## Six tools side by side. The sword has its own image. The computer's tool bar uses these too.
const TOOL_ICONS := preload("res://assets/ui/tool_icons.png")
const SWORD_ICON := preload("res://assets/objects/sword.png")
const TOOL_ICON_SIZE := Vector2(36, 32)
const TEXTURE_SIZE := 64.0
const SELECTED_COLOR := Color(1.4, 1.2, 0.8)
const TOOL_BAR_Y := 340.0
const TOOL_BAR_START_X := 214.0
const TOOL_SIZE := 34.0
const TOOL_SPACING := 36.0
const TOOL_COUNT := 7
## The screen the positions below are written for. Wider phones show more of the world, and
## each control keeps its distance from the edge it belongs to.
const BASE_SIZE := Vector2(640, 360)
const TOOL_BAR_ANCHOR := Vector2(0.5, 1)
## The stick wakes anywhere in this area, so a thumb never has to aim for it: the lower left of
## the screen, up to the tool bar and well clear of the hearts.
const JOYSTICK_BASE_WIDTH := 190.0
const JOYSTICK_TOP_SHARE := 0.4
## Where the ring rests, from the bottom left corner.
const JOYSTICK_REST := Vector2(96, 74)
## Wide screens have room to keep the right-hand buttons away from the curved edge, and a thumb
## reaches them better there. A 16:9 screen has no room to spare.
const MAX_SIDE_INSET := 20.0
## The top right text moves left by this while the pause button sits in its corner.
const PAUSE_TEXT_GAP := 40.0
const TEXT_EDGE_GAP := 8.0
const TOP_RIGHT_TEXT: Array[String] = ["DayLabel", "MoneyRow", "StatusRows"]
## Computers show a help line above the hearts. Phones don't, so these move up into its place.
const HINT_ROOM := 24.0
const TOP_LEFT_Y: Dictionary[String, float] = {"HeartsBar": 32.0, "ToolLabel": 52.0}
## Messages near the bottom stay between the joystick and the seed arrows, wrapping if they must.
## Each row is a label with its bottom edge on a computer, then on a phone, from the screen bottom.
const MESSAGE_SIDE_GAP := 40.0
const TOUCH_MESSAGE_SIDE_GAP := 181.0
const MESSAGE_HEIGHT := 24.0
const MESSAGES: Array[Array] = [["CropStatusLabel", -68.0, -44.0], ["NoticeLabel", -44.0, -92.0]]
## How far right a menu can reach on the base screen, so Bag and Action stay showing.
const MENU_LIMIT := 501.0
## Text, action, center, size, and the edge it follows. Buttons with no text show an icon.
const BAG_ICON := preload("res://assets/ui/bag.png")
const PAUSE_ICON := preload("res://assets/ui/pause_icon.png")
## Smaller and lighter than other icons: full size, the dark bars hid the ring and sank into
## the curse.
const PAUSE_ICON_SIZE := 0.55
const PAUSE_ICON_COLOR := Color(1.8, 1.7, 1.5)
## On Action: "you can do something here", unlike any tool icon. It also closes menus.
const ACT_ICON := preload("res://assets/ui/act_icon.png")
## Which tool icon Action shows. Anything else shows ACT_ICON, and NONE keeps the last icon, dimmed.
const ACTION_ICONS := {
	Farm.Action.SWING: Player.Tool.SWORD,
	Farm.Action.HARVEST: Player.Tool.HAND,
	Farm.Action.WATER: Player.Tool.WATERING_CAN,
	Farm.Action.PLANT: Player.Tool.SEEDS,
	Farm.Action.GATHER: Player.Tool.HAND,
	Farm.Action.TILL: Player.Tool.HOE,
	Farm.Action.PICK_UP: Player.Tool.HAND,
}
const ACTION_DIM_COLOR := Color(1, 1, 1, 0.45)
const HOLY_WATER_ICON := preload("res://assets/items/holy_water.png")
const TASKS_ICON := preload("res://assets/ui/tasks_icon.png")
const BOOK_ICON := preload("res://assets/ui/book_icon.png")
const CANCEL_ICON := preload("res://assets/ui/cancel_icon.png")
## Stands for an open menu in _shown_action, where Action shows ACT_ICON.
const MENU_OPEN := -1
## Makes _process() redraw Action's icon.
const ICON_OUT_OF_DATE := -2
const ACTION_BUTTONS: Array[Array] = [
	["", "action", Vector2(596, 296), 68.0, Vector2.ONE],
	# Well away from Action, so holy water is never spent by accident.
	["", "heal", Vector2(596, 216), 42.0, Vector2.ONE],
	# Storage controls: switches the big button between farming and combat, in Heal's spot.
	["", "switch_mode", Vector2(596, 216), 42.0, Vector2.ONE],
	["", "seed_menu", Vector2(526, 322), 50.0, Vector2.ONE],
	["", "inventory", Vector2(526, 262), 42.0, Vector2.ONE],
	# Under the hearts, away from both thumbs, because it's for reading, not playing.
	["", "tasks", Vector2(28, 78), 38.0, Vector2.ZERO],
	# The old book, right under Tasks: the game's rules, story and help, so it should be easy to find.
	["", "book", Vector2(28, 122), 38.0, Vector2.ZERO],
	# Leaves Build mode. In Seed's spot: they're never both showing.
	["", "build_mode", Vector2(526, 322), 50.0, Vector2.ONE],
	# Pause, in the top right corner: Esc's action, so the pause menu doesn't need to know about touch.
	["", "ui_cancel", Vector2(614, 24), 34.0, Vector2(1, 0)],
]
## The only buttons left showing under an open menu: they're what close it.
const SHOWN_UNDER_MENUS: Array[String] = ["action", "inventory"]
## Storage controls (docs/28_...) swap Heal and Seed for the mode button, and Build mode is a
## mode, so it needs no X.
const CARRY_HIDDEN: Array[String] = ["heal", "seed_menu", "build_mode"]
## Holding the mode button this long opens the wheel: one choice per Player.Mode, in an arc up
## and to the left, where the thumb can slide. Letting go off every choice changes nothing.
const WHEEL_HOLD_SECONDS := 0.3
const WHEEL_OFFSETS: Array[Vector2] = [Vector2(-84, 22), Vector2(-80, -32), Vector2(-50, -74)]
## Storage controls: the Bag is for preparing sets, not for every moment, so it sits small above
## the mode button, in the right-hand column with pause, clear of the top right icons.
const CARRY_BAG_CENTER := Vector2(614, 160)
const CARRY_BAG_SIZE := 34.0
const WHEEL_SLOT := 44.0
const WHEEL_PICK_RADIUS := 30.0
const MODE_ICONS := preload("res://assets/ui/mode_icons.png")
const MODE_ICON_SIZE := 32.0
const STRONG_WATER_ICON := preload("res://assets/items/strong_holy_water.png")
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

@export var player_path: NodePath

## On screens without touch these stay hidden, and the keyboard hints stay on.
var active := false

## The buttons by their input action.
var _buttons: Dictionary[String, TouchScreenButton] = {}
var _action_icon: Sprite2D
var _seed_icon: Sprite2D
var _mode_icon: Sprite2D
## The mode wheel, the finger holding the mode button, for how long, and the choice under it.
var _wheel: Node2D
var _wheel_slots: Array[Sprite2D] = []
var _mode_finger := -1
var _mode_held := 0.0
var _wheel_pick := -1
## What Farm says Action would do, and what the button shows now.
var _action := Farm.Action.NONE
var _shown_action: int = Farm.Action.NONE
## Each control with its position on the base screen and the edge it follows.
var _placed: Array[Dictionary] = []

@onready var player: Player = get_node(player_path)
@onready var tool_bar: Node2D = $ToolBar
@onready var stick: ThumbStick = $Joystick
@onready var hint: Label = get_parent().get_node("Hint")


func _ready() -> void:
	for entry in ACTION_BUTTONS:
		var keep_showing: bool = SHOWN_UNDER_MENUS.has(entry[1])
		var button := _add_button(self if keep_showing else tool_bar, entry[0], entry[1], entry[2], entry[3])
		_follow_edge(button, entry[4])
		_buttons[entry[1]] = button
	_add_icon(_buttons["inventory"], BAG_ICON)
	_add_icon(_buttons["heal"], HOLY_WATER_ICON)
	_add_icon(_buttons["tasks"], TASKS_ICON)
	_add_icon(_buttons["book"], BOOK_ICON)
	_add_icon(_buttons["build_mode"], CANCEL_ICON)
	var pause_icon := _add_icon(_buttons["ui_cancel"], PAUSE_ICON)
	pause_icon.scale *= PAUSE_ICON_SIZE
	pause_icon.modulate = PAUSE_ICON_COLOR
	_action_icon = _add_icon(_buttons["action"], tool_icon(Player.Tool.HOE))
	_buttons["action"].modulate = ACTION_DIM_COLOR
	_buttons["heal"].modulate = ACTION_DIM_COLOR
	_seed_icon = _add_icon(_buttons["seed_menu"], player.selected_seed().seed_icon)
	_mode_icon = _add_icon(_buttons["switch_mode"], mode_icon(Player.Mode.FARM))
	if GameState.carry_mode:
		for action: String in CARRY_HIDDEN:
			_buttons[action].hide()
		player.mode_changed.connect(_show_mode)
		# Taps and holds are read in _input(), because a hold must not switch on its own.
		_buttons["switch_mode"].action = ""
		_add_wheel()
		_move_button("inventory", CARRY_BAG_CENTER, CARRY_BAG_SIZE)
	else:
		_buttons["switch_mode"].hide()
	Inventory.inventory_changed.connect(_show_seed)
	get_viewport().size_changed.connect(_fit_screen)
	_fit_screen()
	player.tool_changed.connect(_show_selected_tool)
	set_active(DisplayServer.is_touchscreen_available())


func _process(delta: float) -> void:
	# Taps would go through an open menu to anything under it.
	var paused := get_tree().paused
	if _mode_finger != -1:
		_mode_held += delta
		if paused:
			_close_wheel()
		elif _mode_held >= WHEEL_HOLD_SECONDS and not _wheel.visible:
			_open_wheel()
	tool_bar.visible = not paused
	if stick.visible == paused:
		stick.visible = not paused
		if paused and active:
			_release_movement()
	var wanted: int = MENU_OPEN if paused else _action
	if wanted != _shown_action:
		_shown_action = wanted
		_update_action_button()


## Called when what the Action button would do changes.
func show_action(action: Farm.Action) -> void:
	_action = action


## Whether a screen position is free of the joystick and every showing button.
func is_free_spot(at: Vector2) -> bool:
	if stick.get_global_rect().has_point(at):
		return false
	for action: String in _buttons:
		var button := _buttons[action]
		if button.is_visible_in_tree() and Rect2(button.global_position, button.texture_normal.get_size() * button.scale).has_point(at):
			return false
	return true


## Called when what the Heal button would do changes.
func show_heal(heal: Farm.Heal) -> void:
	_buttons["heal"].modulate = ACTION_DIM_COLOR if heal == Farm.Heal.NONE else Color.WHITE


func _update_action_button() -> void:
	_buttons["action"].modulate = ACTION_DIM_COLOR if _shown_action == Farm.Action.NONE else Color.WHITE
	if _shown_action == Farm.Action.NONE:
		return
	var icon: Texture2D = ACT_ICON
	if _shown_action == Farm.Action.PLACE:
		icon = player.selected_building().preview_texture
	elif _shown_action == Farm.Action.SHOOT:
		icon = KeyToolBar.BOW_ICON
	elif _shown_action == Farm.Action.HEAL:
		icon = STRONG_WATER_ICON if player.strong_water else HOLY_WATER_ICON
	elif _shown_action == Farm.Action.PLANT and GameState.carry_mode:
		icon = player.selected_seed().seed_icon
	elif ACTION_ICONS.has(_shown_action):
		icon = tool_icon(ACTION_ICONS[_shown_action])
	_fit_icon(_action_icon, icon)


## How much bigger this screen is than the base one.
static func extra_space(item: CanvasItem) -> Vector2:
	return item.get_viewport_rect().size - BASE_SIZE


## How far the right-hand buttons sit in from their base spot.
static func side_inset(item: CanvasItem) -> float:
	return clampf(extra_space(item).x / 4.0, 0.0, MAX_SIDE_INSET)


static func menu_limit(item: CanvasItem) -> float:
	return MENU_LIMIT + extra_space(item).x - side_inset(item)


func _follow_edge(control: CanvasItem, anchor: Vector2) -> void:
	_placed.append({"control": control, "at": control.position, "anchor": anchor})


func _fit_screen() -> void:
	var extra := extra_space(self)
	var inset := side_inset(self)
	for placed: Dictionary in _placed:
		var at: Vector2 = placed["at"] + extra * placed["anchor"]
		if placed["anchor"] == Vector2.ONE:
			at.x -= inset
		placed["control"].position = at
	_fit_joystick()
	_fit_messages()


func _fit_joystick() -> void:
	var screen := get_viewport_rect().size
	var top := roundf(screen.y * JOYSTICK_TOP_SHARE)
	var zone := Vector2(JOYSTICK_BASE_WIDTH + extra_space(self).x / 2.0, screen.y - top)
	stick.position = Vector2(0, top)
	stick.size = zone
	stick.rest = Vector2(JOYSTICK_REST.x, zone.y - JOYSTICK_REST.y)


func set_active(value: bool) -> void:
	active = value
	visible = value
	GameState.touch_mode = value
	hint.visible = not value
	_make_room_for_pause(value)
	_use_hint_room(value)
	_fit_messages()
	if not value:
		_release_movement()
	_show_selected_tool()
	# Help text on screen depends on the controls in use.
	Inventory.inventory_changed.emit()


func _make_room_for_pause(on: bool) -> void:
	var right := -TEXT_EDGE_GAP - (PAUSE_TEXT_GAP if on else 0.0)
	for text_name in TOP_RIGHT_TEXT:
		var text: Control = get_parent().get_node(text_name)
		var width := text.offset_right - text.offset_left
		text.offset_right = right
		text.offset_left = right - width


func _fit_messages() -> void:
	var side := TOUCH_MESSAGE_SIDE_GAP + side_inset(self) if active else MESSAGE_SIDE_GAP
	for message in MESSAGES:
		var label: Label = get_parent().get_node(message[0])
		var bottom: float = message[2] if active else message[1]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if active else TextServer.AUTOWRAP_OFF
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.grow_vertical = Control.GROW_DIRECTION_BEGIN
		label.offset_left = side
		label.offset_right = -side
		label.offset_top = bottom - MESSAGE_HEIGHT
		label.offset_bottom = bottom


func _use_hint_room(on: bool) -> void:
	for item_name: String in TOP_LEFT_Y:
		var item: Control = get_parent().get_node(item_name)
		item.position.y = TOP_LEFT_Y[item_name] - (HINT_ROOM if on else 0.0)


## A hidden joystick can't see its finger lift, so it would keep the player walking.
func _release_movement() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)


func _show_selected_tool() -> void:
	var building := player.tool == Player.Tool.BUILD
	_buttons["build_mode"].visible = building and not GameState.carry_mode
	_buttons["seed_menu"].visible = not building and not GameState.carry_mode
	# A different building can mean a different icon with the same action.
	_shown_action = ICON_OUT_OF_DATE
	_show_seed()


## The seed's picture, dimmed when there are none left: tapping still opens the popup.
## Storage controls: the mode button shows the mode the big button is in.
func _show_mode() -> void:
	_fit_icon(_mode_icon, mode_icon(player.mode))
	_shown_action = ICON_OUT_OF_DATE


## Farm, Combat and Build, side by side in Player.Mode order, unlike any tool icon, so the
## mode button never shows the same picture as the big button.
static func mode_icon(mode: Player.Mode) -> Texture2D:
	var icon := AtlasTexture.new()
	icon.atlas = MODE_ICONS
	icon.region = Rect2(mode * MODE_ICON_SIZE, 0, MODE_ICON_SIZE, MODE_ICON_SIZE)
	return icon


## The mode button: a tap goes to the next mode, and a hold opens the wheel to slide to one.
func _input(event: InputEvent) -> void:
	if not active or not GameState.carry_mode or get_tree().paused:
		return
	var touch := event as InputEventScreenTouch
	var drag := event as InputEventScreenDrag
	if touch and touch.pressed and _mode_finger == -1 and _buttons["switch_mode"].is_visible_in_tree() and _on_button("switch_mode", touch.position):
		_mode_finger = touch.index
		_mode_held = 0.0
		_wheel_pick = -1
	elif touch and not touch.pressed and touch.index == _mode_finger:
		var wheel_was_open := _wheel.visible
		var pick := _wheel_pick
		_close_wheel()
		if not wheel_was_open:
			player.next_mode()
		elif pick >= 0:
			player.set_mode(pick as Player.Mode)
	elif drag and drag.index == _mode_finger and _wheel.visible:
		_wheel_pick = wheel_choice_at(drag.position)
		_show_wheel_pick()


func _move_button(action: String, center: Vector2, size: float) -> void:
	var button := _buttons[action]
	button.scale = Vector2.ONE * size / TEXTURE_SIZE
	for placed: Dictionary in _placed:
		if placed["control"] == button:
			placed["at"] = center - Vector2(size, size) / 2.0


func _on_button(action: String, at: Vector2) -> bool:
	var button := _buttons[action]
	return Rect2(button.global_position, button.texture_normal.get_size() * button.scale).has_point(at)


func _add_wheel() -> void:
	_wheel = Node2D.new()
	_wheel.name = "ModeWheel"
	_wheel.hide()
	add_child(_wheel)
	for mode in Player.Mode.size():
		var slot := Sprite2D.new()
		slot.texture = BUTTON_TEXTURE
		slot.scale = Vector2.ONE * WHEEL_SLOT / TEXTURE_SIZE
		slot.position = WHEEL_OFFSETS[mode]
		var icon := Sprite2D.new()
		_fit_icon(icon, mode_icon(mode as Player.Mode))
		slot.add_child(icon)
		_wheel.add_child(slot)
		_wheel_slots.append(slot)


func _open_wheel() -> void:
	var button := _buttons["switch_mode"]
	_wheel.position = button.global_position + button.texture_normal.get_size() * button.scale / 2.0 - global_position
	_wheel.show()
	_show_wheel_pick()


func _close_wheel() -> void:
	_mode_finger = -1
	_wheel_pick = -1
	_wheel.hide()


## The wheel's choice under a screen point, or -1.
func wheel_choice_at(at: Vector2) -> int:
	for i in _wheel_slots.size():
		if _wheel_slots[i].global_position.distance_to(at) <= WHEEL_PICK_RADIUS:
			return i
	return -1


func _show_wheel_pick() -> void:
	for i in _wheel_slots.size():
		_wheel_slots[i].modulate = SELECTED_COLOR if i == _wheel_pick else Color.WHITE


func _show_seed() -> void:
	var crop := player.selected_seed()
	_fit_icon(_seed_icon, crop.seed_icon)
	_buttons["seed_menu"].modulate = ACTION_DIM_COLOR if Inventory.seed_count(crop) == 0 else Color.WHITE


static func tool_icon(index: int) -> Texture2D:
	if index == TOOL_COUNT - 1:
		return SWORD_ICON
	var icon := AtlasTexture.new()
	icon.atlas = TOOL_ICONS
	icon.region = Rect2(Vector2(index * TOOL_ICON_SIZE.x, 0), TOOL_ICON_SIZE)
	return icon


func _add_icon(button: TouchScreenButton, icon: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.position = Vector2(TEXTURE_SIZE, TEXTURE_SIZE) / 2.0
	_fit_icon(sprite, icon)
	button.add_child(sprite)
	return sprite


## Fits the icon inside the round button, whatever the art's size.
func _fit_icon(sprite: Sprite2D, icon: Texture2D) -> void:
	sprite.texture = icon
	sprite.scale = Vector2.ONE * TEXTURE_SIZE * 0.78 / maxf(icon.get_width(), icon.get_height())


func _add_button(parent: Node, text: String, action: String, center: Vector2, size: float) -> TouchScreenButton:
	var button := TouchScreenButton.new()
	var scale_by := size / TEXTURE_SIZE
	button.texture_normal = BUTTON_TEXTURE
	button.action = action
	button.scale = Vector2(scale_by, scale_by)
	button.position = center - Vector2(size, size) / 2.0
	parent.add_child(button)
	if text.is_empty():
		return button
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16 if size < 40.0 else 24)
	label.size = Vector2(size, size)
	label.scale = Vector2.ONE / scale_by
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(label)
	return button
