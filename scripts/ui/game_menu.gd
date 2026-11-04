class_name GameMenu
extends PanelContainer
## What every menu shares: it pauses the game while open, and closes with a key or Esc.
## Menus keep running while paused because their scene sets process_mode to Always.

## Big enough for a thumb on a phone.
const BUTTON_SIZE := Vector2(92, 36)

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
	show()
	_refresh()
	get_tree().paused = true
	_focus_first_button()


func close() -> void:
	hide()
	get_tree().paused = false


## Override this to draw the menu's contents.
func _refresh() -> void:
	pass


## Override this to give keyboard players a starting point.
func _focus_first_button() -> void:
	pass
