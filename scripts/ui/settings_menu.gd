class_name SettingsMenu
extends PanelContainer
## Music and effects volume, with − and + buttons rather than sliders: they match the button
## art, suit thumbs, and work with keys. Opened from the title now, and later from a pause menu.
## Changes save at once, in Audio's settings.cfg.

signal closed

## Each press changes the volume by this much.
const STEP := 0.1

var _music_value: Label
var _effects_value: Label
var _first_button: Button


func _ready() -> void:
	var margin := MarginContainer.new()
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_music_value = _add_row(box, "Music", Audio.set_music_volume, func() -> float: return Audio.music_volume)
	_effects_value = _add_row(box, "Effects", Audio.set_effects_volume, func() -> float: return Audio.effects_volume)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(0, 34)
	back.pressed.connect(close)
	box.add_child(back)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func open() -> void:
	show()
	_refresh()
	_first_button.grab_focus()


func close() -> void:
	hide()
	closed.emit()


## One line: name, −, the volume in percent, +.
func _add_row(box: VBoxContainer, label_text: String, set_volume: Callable, get_volume: Callable) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(90, 0)
	row.add_child(label)
	var value := Label.new()
	value.custom_minimum_size = Vector2(60, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for step: float in [-STEP, STEP]:
		var button := Button.new()
		button.name = "%s%s" % [label_text, "Down" if step < 0 else "Up"]
		button.text = "-" if step < 0 else "+"
		button.custom_minimum_size = Vector2(44, 34)
		button.pressed.connect(func() -> void:
			set_volume.call(snappedf(get_volume.call() + step, STEP))
			_refresh())
		row.add_child(button)
		if step < 0:
			row.add_child(value)
		if not _first_button:
			_first_button = button
	box.add_child(row)
	return value


func _refresh() -> void:
	_music_value.text = _percent(Audio.music_volume)
	_effects_value.text = _percent(Audio.effects_volume)


func _percent(volume: float) -> String:
	return "Off" if volume <= 0.0 else "%d%%" % roundi(volume * 100.0)
