class_name TasksMenu
extends GameMenu
## The goals, in one place instead of on the screen: what to do now, the long goal, and what's
## done. The Tasks button or key G opens it. GoalGuide decides what the goals are.

const LIST_SIZE := Vector2(352, 190)
const HEADING_COLOR := Color(1.0, 0.9, 0.6)
const DONE_COLOR := Color(1, 1, 1, 0.6)

## Everything listed, for tests.
var list_text := ""

var _guide: GoalGuide
var _rows := VBoxContainer.new()


func _init() -> void:
	name = "TasksMenu"
	keyboard_help = "G / Esc: close"
	touch_help = ""
	_build_frame()
	var title := Label.new()
	title.text = "Tasks"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_above_help(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = LIST_SIZE
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 2)
	scroll.add_child(_rows)
	_add_above_help(scroll)


func setup(guide: GoalGuide) -> void:
	_guide = guide


func _unhandled_input(event: InputEvent) -> void:
	if not visible and not get_tree().paused and event.is_action_pressed("tasks"):
		get_viewport().set_input_as_handled()
		open()
	else:
		super(event)


func _is_close(event: InputEvent) -> bool:
	return super(event) or event.is_action_pressed("tasks")


func _refresh() -> void:
	if not visible:
		return
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	var lines: PackedStringArray = []
	var now := _guide.lesson_text()
	if not now.is_empty():
		lines.append(_add_row("Now", HEADING_COLOR))
		lines.append(_add_row(now, Color.WHITE))
	lines.append(_add_row("The long goal", HEADING_COLOR))
	lines.append(_add_row(_guide.long_goal_text(), Color.WHITE))
	var done := _guide.done_names()
	if not done.is_empty():
		lines.append(_add_row("Done", HEADING_COLOR))
	for name_done in done:
		lines.append(_add_row(name_done, DONE_COLOR))
	list_text = "\n".join(lines)


func _add_row(text: String, color: Color) -> String:
	var row := Label.new()
	row.text = text
	row.modulate = color
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.custom_minimum_size.x = LIST_SIZE.x - 12.0
	_rows.add_child(row)
	return text
