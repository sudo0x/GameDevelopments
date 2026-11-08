class_name BookMenu
extends GameMenu
## The old book: the island's story and how to play. It opens from the Bag or key B, and new
## pages appear as the land heals (Progress.book_pages). Pages stay once found, even if the
## curse takes the land back.

const TEXT_SIZE := Vector2(372, 176)
const PAGE_STYLE := preload("res://data/ui/book_panel.tres")

## The page showing now, from 0.
var page := 0

var _title := Label.new()
var _text := Label.new()
var _count := Label.new()
var _back := Button.new()
var _next := Button.new()


func _init() -> void:
	name = "BookMenu"
	keyboard_help = "Left / Right: turn   B / Esc: close"
	touch_help = ""
	_build_frame()
	add_theme_stylebox_override("panel", PAGE_STYLE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_above_help(_title)
	_text.custom_minimum_size = TEXT_SIZE
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_above_help(_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	_add_above_help(row)
	_back.text = "Back"
	_next.text = "Next"
	_back.custom_minimum_size = BUTTON_SIZE
	_next.custom_minimum_size = BUTTON_SIZE
	_count.custom_minimum_size.x = 80
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_back)
	row.add_child(_count)
	row.add_child(_next)


func _ready() -> void:
	super()
	_back.pressed.connect(_turn.bind(-1))
	_next.pressed.connect(_turn.bind(1))


func _unhandled_input(event: InputEvent) -> void:
	if not visible and not get_tree().paused and event.is_action_pressed("book"):
		get_viewport().set_input_as_handled()
		open()
	elif visible and event.is_action_pressed("ui_left"):
		_turn(-1)
	elif visible and event.is_action_pressed("ui_right"):
		_turn(1)
	else:
		super(event)


## Opens on the newest page, since that's the one worth reading.
func open() -> void:
	page = Progress.book_pages - 1
	super()


func _is_close(event: InputEvent) -> bool:
	return super(event) or event.is_action_pressed("book")


func _turn(step: int) -> void:
	page = clampi(page + step, 0, Progress.book_pages - 1)
	_refresh()


func _refresh() -> void:
	if not visible:
		return
	var entry: Array = BookPages.PAGES[page]
	_title.text = entry[1]
	var text: String = entry[2]
	text = text.replace("{action}", GameState.controls("R", "the big button"))
	var heal := GameState.controls("the holy water tool (5, then Space)", "the bottle")
	if GameState.carry_mode:
		heal = "the big button on a cursed tile, with holy water in your farming set"
	_text.text = text.replace("{heal}", heal)
	_count.text = "%d / %d" % [page + 1, Progress.book_pages]
	_back.disabled = page == 0
	_next.disabled = page == Progress.book_pages - 1


func _focus_first_button() -> void:
	_back.grab_focus() if _next.disabled and not _back.disabled else _next.grab_focus()
