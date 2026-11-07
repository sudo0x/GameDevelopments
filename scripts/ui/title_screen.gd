extends Control
## The first screen: Continue, New Game and Quit. Starting over asks first if a save exists.

const GAME_SCENE := "res://scenes/main/main.tscn"

@onready var continue_button: Button = $Center/Box/Continue
@onready var new_game_button: Button = $Center/Box/NewGame
@onready var settings_button: Button = $Center/Box/Settings
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var quit_button: Button = $Center/Box/Quit
@onready var confirm: PanelContainer = $Confirm
@onready var confirm_label: Label = $Confirm/Margin/Box/Message
@onready var confirm_yes: Button = $Confirm/Margin/Box/Buttons/Yes
@onready var confirm_no: Button = $Confirm/Margin/Box/Buttons/No


func _ready() -> void:
	continue_button.pressed.connect(_start_game)
	new_game_button.pressed.connect(_on_new_game)
	quit_button.pressed.connect(get_tree().quit)
	settings_button.pressed.connect(_open_settings)
	settings_menu.closed.connect(_on_settings_closed)
	Audio.play_music(&"title")
	confirm_yes.pressed.connect(_erase_and_start)
	confirm_no.pressed.connect(_cancel_new_game)
	var has_save := SaveGame.has_save()
	continue_button.visible = has_save
	continue_button.text = "Continue (Day %d)" % Progress.day
	# Phones have their own way to leave an app.
	quit_button.visible = not OS.has_feature("mobile")
	(continue_button if has_save else new_game_button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if confirm.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel_new_game()


func _on_new_game() -> void:
	if not SaveGame.has_save():
		_erase_and_start()
		return
	confirm_label.text = "Start over? Your farm on Day %d will be gone for good." % Progress.day
	confirm.show()
	# "No" first, so pressing Enter by accident can't erase a farm.
	confirm_no.grab_focus()


## The title's own buttons hide behind the panel, so keys can't reach them.
func _open_settings() -> void:
	$Center.hide()
	settings_menu.open()


func _on_settings_closed() -> void:
	$Center.show()
	settings_button.grab_focus()


func _cancel_new_game() -> void:
	confirm.hide()
	new_game_button.grab_focus()


func _erase_and_start() -> void:
	SaveGame.start_new_game()
	_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
