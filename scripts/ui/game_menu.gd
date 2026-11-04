class_name GameMenu
extends PanelContainer
## What every menu shares: it pauses the game while open, and closes with a key or Esc.
## Menus keep running while paused because their scene sets process_mode to Always.

## Big enough for a thumb on a phone.
const BUTTON_SIZE := Vector2(92, 36)
const ICON_SIZE := Vector2(24, 24)
## On touch screens menus sit left of center, to stay clear of the buttons that close them.
const TOUCH_CENTER_X := 0.39
const HOLY_WATER_ICON := preload("res://assets/items/holy_water.png")
const STRONG_WATER_ICON := preload("res://assets/items/strong_holy_water.png")

## The key that closes this menu, besides Esc.
@export var close_action: StringName = &"interact"
@export var keyboard_help: String
@export var touch_help: String


func _ready() -> void:
	GameState.inventory_changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(close_action) or event.is_action_pressed("ui_cancel")):
		# Handled, so the same key press can't reach the player and reopen the menu.
		get_viewport().set_input_as_handled()
		close()


func open() -> void:
	$Margin/Box/Help.text = GameState.controls(keyboard_help, touch_help)
	var center_x := TOUCH_CENTER_X if GameState.touch_mode else 0.5
	anchor_left = center_x
	anchor_right = center_x
	show()
	_refresh()
	get_tree().paused = true
	_focus_first_button()


func close() -> void:
	hide()
	get_tree().paused = false


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
