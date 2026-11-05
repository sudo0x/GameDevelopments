class_name TouchControls
extends Node2D
## On-screen controls for phones. Every button presses a normal input action, so game code
## works the same with touch and keyboard. Built from the tables below.
## TouchScreenButton is used because, unlike Button, it works while another finger is down.

const BUTTON_TEXTURE := preload("res://assets/ui/touch_button.png")
## Six tools side by side. The sword has its own image.
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
const JOYSTICK_ANCHOR := Vector2(0, 1)
## Wide screens have room to keep the right-hand buttons away from the curved edge, and a thumb
## reaches them better there. A 16:9 screen has no room to spare.
const MAX_SIDE_INSET := 20.0
## Where the Act button starts on the base screen.
const ACT_LEFT := 501.0
## Text, action, center, size, and the edge it follows. Buttons with no text show an icon: Bag,
## Act and pause have their own, and Use shows the selected tool, so you can see what it will do.
const BAG_ICON := preload("res://assets/ui/bag.png")
const PAUSE_ICON := preload("res://assets/ui/pause_icon.png")
## Act (interact): "you can do something here", unlike any tool icon.
const ACT_ICON := preload("res://assets/ui/act_icon.png")
const ACTION_BUTTONS: Array[Array] = [
	["", "use_tool", Vector2(596, 296), 68.0, Vector2.ONE],
	["", "interact", Vector2(526, 322), 50.0, Vector2.ONE],
	["", "inventory", Vector2(526, 262), 42.0, Vector2.ONE],
	["<", "seed_prev", Vector2(476, 300), 34.0, Vector2.ONE],
	[">", "seed_next", Vector2(476, 340), 34.0, Vector2.ONE],
	# Pause: Esc's action, so the pause menu doesn't need to know about touch.
	["", "ui_cancel", Vector2(320, 22), 34.0, Vector2(0.5, 0)],
]
## The only buttons left showing under an open menu: they're what close it.
const SHOWN_UNDER_MENUS: Array[String] = ["use_tool", "interact", "inventory"]
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

@export var player_path: NodePath

## On screens without touch these stay hidden, and the keyboard hints stay on.
var active := false

var _tool_buttons: Array[TouchScreenButton] = []
var _use_icon: Sprite2D
## Each control with its position on the base screen and the edge it follows.
var _placed: Array[Dictionary] = []

@onready var player: Player = get_node(player_path)
@onready var tool_bar: Node2D = $ToolBar
@onready var hint: Label = get_parent().get_node("Hint")


func _ready() -> void:
	for i in TOOL_COUNT:
		var at := Vector2(TOOL_BAR_START_X + i * TOOL_SPACING, TOOL_BAR_Y)
		var button := _add_button(tool_bar, "", "tool_%d" % (i + 1), at, TOOL_SIZE)
		_add_icon(button, tool_icon(i))
		_tool_buttons.append(button)
		_follow_edge(button, TOOL_BAR_ANCHOR)
	for entry in ACTION_BUTTONS:
		var keep_showing: bool = SHOWN_UNDER_MENUS.has(entry[1])
		var button := _add_button(self if keep_showing else tool_bar, entry[0], entry[1], entry[2], entry[3])
		_follow_edge(button, entry[4])
		if entry[1] == "inventory":
			_add_icon(button, BAG_ICON)
		elif entry[1] == "ui_cancel":
			_add_icon(button, PAUSE_ICON)
		elif entry[1] == "interact":
			_add_icon(button, ACT_ICON)
		elif entry[1] == "use_tool":
			_use_icon = _add_icon(button, tool_icon(0))
	_follow_edge($Joystick, JOYSTICK_ANCHOR)
	get_viewport().size_changed.connect(_fit_screen)
	_fit_screen()
	player.tool_changed.connect(_show_selected_tool)
	set_active(DisplayServer.is_touchscreen_available())


func _process(_delta: float) -> void:
	# Taps would go through an open menu to anything under it.
	tool_bar.visible = not get_tree().paused


## How much bigger this screen is than the base one.
static func extra_space(item: CanvasItem) -> Vector2:
	return item.get_viewport_rect().size - BASE_SIZE


## How far the right-hand buttons sit in from their base spot.
static func side_inset(item: CanvasItem) -> float:
	return clampf(extra_space(item).x / 4.0, 0.0, MAX_SIDE_INSET)


static func act_left(item: CanvasItem) -> float:
	return ACT_LEFT + extra_space(item).x - side_inset(item)


func _follow_edge(control: CanvasItem, anchor: Vector2) -> void:
	_placed.append({"control": control, "at": control.position, "anchor": anchor})


func _fit_screen() -> void:
	var extra := extra_space(self)
	var inset := side_inset(self)
	for placed: Dictionary in _placed:
		var at: Vector2 = placed["at"] + extra * placed["anchor"]
		if placed["anchor"].x == 1.0:
			at.x -= inset
		placed["control"].position = at


func set_active(value: bool) -> void:
	active = value
	visible = value
	GameState.touch_mode = value
	hint.visible = not value
	if not value:
		_release_movement()
	_show_selected_tool()
	# Help text on screen depends on the controls in use.
	GameState.inventory_changed.emit()


## A hidden joystick can't see its finger lift, so it would keep the player walking.
func _release_movement() -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)


func _show_selected_tool() -> void:
	for i in _tool_buttons.size():
		_tool_buttons[i].modulate = SELECTED_COLOR if i == player.tool else Color.WHITE
	_fit_icon(_use_icon, tool_icon(player.tool))


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
