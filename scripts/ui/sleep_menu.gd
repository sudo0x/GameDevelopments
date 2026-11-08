class_name SleepMenu
extends GameMenu
## Asks before the Action button ends the day. Action does many jobs, so a tap beside the
## house may be meant for something else, and sleeping can't be undone.

var _no := Button.new()
var _yes := Button.new()


func _init() -> void:
	name = "SleepMenu"
	keyboard_help = "Enter: choose   Esc: close"
	touch_help = ""
	_build_frame()
	var question := Label.new()
	question.text = "Sleep until morning?"
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_above_help(question)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	_add_above_help(buttons)
	for entry: Array in [[_no, "No"], [_yes, "Yes"]]:
		var button: Button = entry[0]
		button.text = entry[1]
		button.custom_minimum_size = BUTTON_SIZE
		buttons.add_child(button)


func _ready() -> void:
	super()
	GameState.sleep_asked.connect(open)
	_no.pressed.connect(close)
	_yes.pressed.connect(_sleep)


## "No" first, so a stray key can't end the day.
func _focus_first_button() -> void:
	_no.grab_focus()


func _sleep() -> void:
	close()
	Audio.play(&"sleep")
	GameState.request_sleep()
