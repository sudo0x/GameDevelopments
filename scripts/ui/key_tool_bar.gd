class_name KeyToolBar
extends Node2D
## The tool bar on computers: the phone's tool icons in the same place, each with its number
## key, and the selected tool highlighted. Clicking a slot sends that key's action, so the
## player can't tell a click from the key. Hidden while touch controls are on, which have
## their own tappable bar.

const NUMBER_OFFSET := Vector2(-15, -19)

@export var player_path: NodePath

var _slots: Array[Sprite2D] = []

@onready var player: Player = get_node(player_path)


func _ready() -> void:
	for i in TouchControls.TOOL_COUNT:
		var at := Vector2(TouchControls.TOOL_BAR_START_X + i * TouchControls.TOOL_SPACING, TouchControls.TOOL_BAR_Y)
		var slot := Sprite2D.new()
		slot.texture = TouchControls.BUTTON_TEXTURE
		slot.position = at
		slot.scale = Vector2.ONE * TouchControls.TOOL_SIZE / TouchControls.TEXTURE_SIZE
		add_child(slot)
		var icon := Sprite2D.new()
		icon.texture = TouchControls.tool_icon(i)
		icon.scale = Vector2.ONE * TouchControls.TEXTURE_SIZE * 0.78 / maxf(icon.texture.get_width(), icon.texture.get_height())
		slot.add_child(icon)
		var number := Label.new()
		number.text = str(i + 1)
		number.add_theme_font_size_override("font_size", 16)
		number.position = at + NUMBER_OFFSET
		add_child(number)
		_slots.append(slot)
	get_viewport().size_changed.connect(_fit_screen)
	_fit_screen()
	player.tool_changed.connect(_show_selected)
	# Touch controls emit this when they turn on or off.
	Inventory.inventory_changed.connect(_update_visible)
	_show_selected()
	_update_visible()


func _fit_screen() -> void:
	position = TouchControls.extra_space(self) * TouchControls.TOOL_BAR_ANCHOR


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if not visible or get_tree().paused or not click or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var at: Vector2 = (make_input_local(click) as InputEventMouseButton).position
	for i in _slots.size():
		if at.distance_to(_slots[i].position) <= TouchControls.TOOL_SIZE / 2.0:
			get_viewport().set_input_as_handled()
			_press("tool_%d" % (i + 1))
			return


func _press(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)


func _show_selected() -> void:
	for i in _slots.size():
		_slots[i].modulate = TouchControls.SELECTED_COLOR if i == player.tool else Color.WHITE


func _update_visible() -> void:
	# Storage controls have no tools to pick: the bag page sets what the big button uses.
	visible = not GameState.touch_mode and not GameState.carry_mode


const BOW_ICON := preload("res://assets/items/bow.png")
const ARROWS_ICON := preload("res://assets/items/arrows.png")


## Storage controls (docs/28_...): the picture for a bag item, shared by the bag and storage.
static func item_icon(item: StringName) -> Texture2D:
	match item:
		&"hoe":
			return TouchControls.tool_icon(Player.Tool.HOE)
		&"can":
			return TouchControls.tool_icon(Player.Tool.WATERING_CAN)
		&"sword":
			return TouchControls.SWORD_ICON
		&"bow":
			return BOW_ICON
		&"arrows":
			return ARROWS_ICON
		&"holy_water":
			return GameMenu.HOLY_WATER_ICON
		&"strong_holy_water":
			return GameMenu.STRONG_WATER_ICON
	var text := String(item)
	var id := StringName(text.substr(text.find("_") + 1))
	if text.begins_with("seed_"):
		return Inventory.crop_by_id(id).seed_icon
	if text.begins_with("crop_"):
		return Inventory.crop_by_id(id).icon
	if text.begins_with("build_"):
		return Inventory.building_by_id(id).preview_texture
	for material in Inventory.MATERIALS:
		if material.id == id:
			return material.icon
	return null
