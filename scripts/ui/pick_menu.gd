class_name PickMenu
extends GameMenu
## A small popup that asks the player to pick one thing, such as a seed.
## Each choice is a Dictionary: "text", "icon", "pick" (a Callable) and optional "dim".

const ROW_SIZE := Vector2(220, 36)
const DIM_COLOR := Color(1, 1, 1, 0.55)
## Rows past this scroll, so a long list can't run off a phone's screen.
const MOST_ROWS_SHOWING := 5
const ROW_GAP := 4

var _title := Label.new()
var _rows := VBoxContainer.new()
var _scroll := ScrollContainer.new()
var _first_row: Button


func _init() -> void:
	name = "PickMenu"
	keyboard_help = "Enter: pick   Esc: close"
	touch_help = "Tap ! to close"
	_build_frame()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_above_help(_title)
	_rows.add_theme_constant_override("separation", ROW_GAP)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.add_child(_rows)
	_add_above_help(_scroll)


func ask(title: String, choices: Array[Dictionary]) -> void:
	_title.text = title
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	_first_row = null
	for choice in choices:
		_rows.add_child(_make_row(choice))
	var showing := mini(choices.size(), MOST_ROWS_SHOWING)
	_scroll.custom_minimum_size = Vector2(ROW_SIZE.x, showing * (ROW_SIZE.y + ROW_GAP) - ROW_GAP)
	_scroll.scroll_vertical = 0
	open()


func _make_row(choice: Dictionary) -> Button:
	var row := Button.new()
	row.text = choice["text"]
	row.icon = choice["icon"]
	row.add_theme_constant_override("icon_max_width", int(ICON_SIZE.x))
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.custom_minimum_size = ROW_SIZE
	if choice.get("dim", false):
		row.modulate = DIM_COLOR
	row.pressed.connect(_pick.bind(choice["pick"]))
	if not _first_row:
		_first_row = row
	return row


func _pick(pick: Callable) -> void:
	close()
	pick.call()


func _focus_first_button() -> void:
	if _first_row:
		_first_row.grab_focus()
