class_name GameMenu
extends PanelContainer
## What every menu shares: it pauses the game while open, and closes with a key or Esc.
## Menus keep running while paused because their scene sets process_mode to Always.

## Big enough for a thumb on a phone.
const BUTTON_SIZE := Vector2(92, 36)
const ICON_SIZE := Vector2(24, 24)
## The gap kept between a menu and the buttons that stay showing under it.
const ACT_GAP := 4.0
const HOLY_WATER_ICON := preload("res://assets/items/holy_water.png")
const STRONG_WATER_ICON := preload("res://assets/items/strong_holy_water.png")

## The key that closes this menu, besides Esc.
@export var close_action: StringName = &"interact"
@export var keyboard_help: String
@export var touch_help: String


func _ready() -> void:
	Inventory.inventory_changed.connect(_refresh)
	resized.connect(_place)


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
		center = minf(center, TouchControls.act_left(self) - ACT_GAP - size.x / 2.0)
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


## Override this to draw the menu's contents.
func _refresh() -> void:
	pass


## Override this to give keyboard players a starting point.
func _focus_first_button() -> void:
	pass
