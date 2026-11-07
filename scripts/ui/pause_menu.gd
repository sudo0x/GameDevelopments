extends GameMenu
## The pause menu: Esc (or the pause button on phones) when no other menu is open.
## Resume, Settings (the same SettingsMenu as the title), and Back to title, which asks first
## because anything since the morning's save is lost.

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"

@export var settings_path: NodePath

@onready var settings: SettingsMenu = get_node(settings_path)
@onready var buttons: VBoxContainer = $Margin/Box/Buttons
@onready var resume_button: Button = $Margin/Box/Buttons/Resume
@onready var settings_button: Button = $Margin/Box/Buttons/Settings
@onready var title_button: Button = $Margin/Box/Buttons/Title
@onready var confirm: VBoxContainer = $Margin/Box/Confirm
@onready var confirm_no: Button = $Margin/Box/Confirm/Buttons/No
@onready var confirm_yes: Button = $Margin/Box/Confirm/Buttons/Yes


func _ready() -> void:
	super()
	resume_button.pressed.connect(close)
	settings_button.pressed.connect(_open_settings)
	title_button.pressed.connect(_ask_leave)
	confirm_no.pressed.connect(_cancel_leave)
	confirm_yes.pressed.connect(_leave)
	settings.closed.connect(_on_settings_closed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible and not get_tree().paused and not Progress.day_changing and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		open()
	elif visible and confirm.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel_leave()
	else:
		super(event)


func open() -> void:
	confirm.hide()
	buttons.show()
	super()


func _focus_first_button() -> void:
	resume_button.grab_focus()


## The settings panel takes this menu's place; the game stays paused.
func _open_settings() -> void:
	hide()
	settings.open()


func _on_settings_closed() -> void:
	show()
	settings_button.grab_focus()


func _ask_leave() -> void:
	buttons.hide()
	confirm.show()
	# "No" first, so a stray key can't throw away the day.
	confirm_no.grab_focus()


func _cancel_leave() -> void:
	confirm.hide()
	buttons.show()
	title_button.grab_focus()


func _leave() -> void:
	SaveGame.discard_unsaved()
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
