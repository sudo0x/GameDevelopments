class_name GameMenu
extends PanelContainer
## What every menu shares: it pauses the game while open, and closes with a key or Esc.
## Menus keep running while paused because their scene sets process_mode to Always.

## Big enough for a thumb on a phone.
const BUTTON_SIZE := Vector2(92, 36)
const ICON_SIZE := Vector2(24, 24)
## The gap kept between a menu and the buttons that stay showing under it.
const MENU_GAP := 4.0
const HOLY_WATER_ICON := preload("res://assets/items/holy_water.png")
const STRONG_WATER_ICON := preload("res://assets/items/strong_holy_water.png")
const CLOSE_ICON := preload("res://assets/ui/cancel_icon.png")
const CLOSE_SIZE := 32.0
## How far the X reaches past the frame's top right corner.
const CLOSE_OUTSIDE := 12.0

## The key that closes this menu, besides Esc.
@export var close_action: StringName = &"interact"
@export var keyboard_help: String
@export var touch_help: String


func _ready() -> void:
	Inventory.inventory_changed.connect(_refresh)
	resized.connect(_place)
	_add_close_button()


## An X on the top right corner, so every menu closes the same way, on phones and computers.
## It sits half outside the frame, so it never covers a menu's own buttons. A container lays out
## its children, so the X goes in a plain full-size Control that only places it.
func _add_close_button() -> void:
	var overlay := Control.new()
	overlay.name = "CloseOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var button := Button.new()
	button.name = "CloseButton"
	button.icon = CLOSE_ICON
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -CLOSE_SIZE + CLOSE_OUTSIDE
	button.offset_right = CLOSE_OUTSIDE
	button.offset_top = -CLOSE_OUTSIDE
	button.offset_bottom = CLOSE_SIZE - CLOSE_OUTSIDE
	button.pressed.connect(close)
	overlay.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
	if visible and (_is_close(event) or event.is_action_pressed("ui_cancel")):
		# Handled, so the same key press can't reach the player and reopen the menu.
		get_viewport().set_input_as_handled()
		close()


## Menus opened by using an object close with the same button that opened them.
func _is_close(event: InputEvent) -> bool:
	return event.is_action_pressed(close_action) or (close_action == &"interact" and event.is_action_pressed("action"))


func open() -> void:
	$Margin/Box/Help.text = GameState.controls(keyboard_help, touch_help)
	# The X closes every menu, so a phone menu with nothing else to say has no help line.
	$Margin/Box/Help.visible = not $Margin/Box/Help.text.is_empty()
	show()
	_refresh()
	_place()
	get_tree().paused = true
	Audio.play(&"menu_open")
	_focus_first_button()


func close() -> void:
	hide()
	get_tree().paused = false
	Audio.play(&"menu_close")


## Centered, unless that would cover the buttons on the right: then only as far left as it takes.
func _place() -> void:
	var width := get_viewport_rect().size.x
	var center := width / 2.0
	if GameState.touch_mode:
		center = minf(center, TouchControls.menu_limit(self) - MENU_GAP - size.x / 2.0)
	anchor_left = center / width
	anchor_right = anchor_left


## A fixed-size picture, so rows line up however big the art is.
func _icon(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = ICON_SIZE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect


## For menus built in code: the frame and help line that open() expects.
func _build_frame() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_anchors_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin := MarginContainer.new()
	margin.name = "Margin"
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	add_child(margin)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	var help := Label.new()
	help.name = "Help"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(help)


## Adds to a menu from _build_frame(), keeping the help line last.
func _add_above_help(item: Control) -> void:
	var box: VBoxContainer = $Margin/Box
	box.add_child(item)
	box.move_child(box.get_node("Help"), -1)


## Override this to draw the menu's contents.
func _refresh() -> void:
	pass


## Override this to give keyboard players a starting point.
func _focus_first_button() -> void:
	pass
