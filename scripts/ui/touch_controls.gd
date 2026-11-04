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
## Text, action, center, size. A button with no text shows BAG_ICON.
const BAG_ICON := preload("res://assets/ui/bag.png")
const ACTION_BUTTONS: Array[Array] = [
	["Use", "use_tool", Vector2(596, 296), 68.0],
	["Act", "interact", Vector2(526, 322), 50.0],
	["", "inventory", Vector2(526, 262), 42.0],
	["<", "seed_prev", Vector2(476, 300), 34.0],
	[">", "seed_next", Vector2(476, 340), 34.0],
]
const TOOL_LABEL_TOUCH_Y := 52.0
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]

@export var player_path: NodePath

## On screens without touch these stay hidden, and the keyboard hints stay on.
var active := false

var _tool_buttons: Array[TouchScreenButton] = []

@onready var player: Player = get_node(player_path)
@onready var tool_bar: Node2D = $ToolBar
@onready var hint: Label = get_parent().get_node("Hint")
@onready var tool_label: Label = get_parent().get_node("ToolLabel")


func _ready() -> void:
	for i in TOOL_COUNT:
		var at := Vector2(TOOL_BAR_START_X + i * TOOL_SPACING, TOOL_BAR_Y)
		var button := _add_button(tool_bar, "", "tool_%d" % (i + 1), at, TOOL_SIZE)
		_add_icon(button, _tool_icon(i))
		_tool_buttons.append(button)
	for entry in ACTION_BUTTONS:
		# Only Act and Bag stay under a menu: they're what close it.
		var keep_showing: bool = entry[1] != "seed_prev" and entry[1] != "seed_next"
		var button := _add_button(self if keep_showing else tool_bar, entry[0], entry[1], entry[2], entry[3])
		if entry[0].is_empty():
			_add_icon(button, BAG_ICON)
	player.tool_changed.connect(_show_selected_tool)
	set_active(DisplayServer.is_touchscreen_available())


func _process(_delta: float) -> void:
	# Taps would go through an open menu to anything under it.
	tool_bar.visible = not get_tree().paused


func set_active(value: bool) -> void:
	active = value
	visible = value
	GameState.touch_mode = value
	hint.visible = not value
	# The joystick sits where this label normally is.
	tool_label.position.y = TOOL_LABEL_TOUCH_Y if value else tool_label.position.y
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


func _tool_icon(index: int) -> Texture2D:
	if index == TOOL_COUNT - 1:
		return SWORD_ICON
	var icon := AtlasTexture.new()
	icon.atlas = TOOL_ICONS
	icon.region = Rect2(Vector2(index * TOOL_ICON_SIZE.x, 0), TOOL_ICON_SIZE)
	return icon


func _add_icon(button: TouchScreenButton, icon: Texture2D) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = icon
	sprite.position = Vector2(TEXTURE_SIZE, TEXTURE_SIZE) / 2.0
	# Fits inside the round button, whatever the art's size.
	sprite.scale = Vector2.ONE * TEXTURE_SIZE * 0.78 / maxf(icon.get_width(), icon.get_height())
	button.add_child(sprite)


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
