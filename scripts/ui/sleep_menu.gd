class_name SleepMenu
extends GameMenu
## Asks before the Action button ends the day. Action does many jobs, so a tap beside the
## house may be meant for something else, and sleeping can't be undone.
## Built in code because it's only a question and two buttons.

var _no := Button.new()
var _yes := Button.new()


func _init() -> void:
	name = "SleepMenu"
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	keyboard_help = "Enter: choose   Esc: close"
	touch_help = "Tap ! to close"
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
	var question := Label.new()
	question.text = "Sleep until morning?"
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(question)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)
	for entry: Array in [[_no, "No"], [_yes, "Yes"]]:
		var button: Button = entry[0]
		button.text = entry[1]
		button.custom_minimum_size = BUTTON_SIZE
		buttons.add_child(button)
	var help := Label.new()
	help.name = "Help"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(help)


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
