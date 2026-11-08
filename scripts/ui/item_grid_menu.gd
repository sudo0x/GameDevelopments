class_name ItemGridMenu
extends GameMenu
## The shared layout for menus full of items (workbench, stall, storage), so they grow with the
## game: tabs on top filter by kind, a grid of tiles scrolls on the left, and the tapped item's
## details and buttons sit on the right. A menu only says what its items are, never how to lay
## them out: override _entries() and _details(), and give the tab names.
## Built in code, like the bag page. Storage controls only (docs/28_...).

const TILE_SIZE := Vector2(46, 40)
const COLUMNS := 5
## Five tiles across plus a scroll bar, and four rows down, on the smallest screen.
const GRID_SIZE := Vector2(250, 172)
const DETAIL_WIDTH := 190.0
const BUTTON_HEIGHT := 30.0
const PICKED_COLOR := Color(1.4, 1.2, 0.8)
const DIM_COLOR := Color(1, 1, 1, 0.45)
const ALL := "All"

## Every tile and the details, in words, for tests.
var tiles_text := ""
var details_text := ""

var _tab := ALL
var _picked: StringName = &""
## While a details button runs, the picked item stays picked even if it leaves the tab, so
## "Don't plant" on the Ready tab can be undone with the next tap.
var _keep_picked := false
var _title := Label.new()
var _tabs := HBoxContainer.new()
## The tiles, in one grid per section, each under its heading.
var _list := VBoxContainer.new()
## Every tile showing, for keyboard focus.
var _tiles: Array[Button] = []
var _detail_icon := TextureRect.new()
var _detail_name := Label.new()
var _detail_text := Label.new()
var _detail_info := Label.new()
var _detail_buttons := VBoxContainer.new()


func _init() -> void:
	_build_frame()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_above_help(_title)
	_tabs.add_theme_constant_override("separation", 2)
	_add_above_help(_tabs)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = GRID_SIZE
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_list)
	body.add_child(scroll)
	body.add_child(_detail_panel())
	_add_above_help(body)
	$Margin/Box/Help.add_theme_font_size_override("font_size", 16)


func _detail_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = DETAIL_WIDTH
	panel.add_theme_constant_override("separation", 4)
	var top := HBoxContainer.new()
	_detail_icon.custom_minimum_size = Vector2(32, 32)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(_detail_icon)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_detail_name)
	panel.add_child(top)
	for label in [_detail_text, _detail_info]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = DETAIL_WIDTH
		label.add_theme_font_size_override("font_size", 16)
		panel.add_child(label)
	_detail_info.modulate = Color(1.0, 0.9, 0.6)
	# The buttons sit at the bottom, where the thumb expects them.
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(gap)
	_detail_buttons.add_theme_constant_override("separation", 2)
	panel.add_child(_detail_buttons)
	return panel


## Override: the menu's title.
func _menu_title() -> String:
	return ""


## Override: the tabs after All, in order.
func _tab_names() -> Array[String]:
	return []


## Override: every tab in order. All comes first unless a menu puts another tab before it.
func _tab_list() -> Array[String]:
	var names: Array[String] = [ALL]
	names.append_array(_tab_names())
	return names


## Override: the tab the menu opens on.
func _first_tab() -> String:
	return ALL


## Override: one Dictionary per tile, in order: id, icon, kind (a tab name), count (short
## text on the tile) and dim (true for something that can't be used now). only_in_tab keeps a
## tile out of All, for a tab that repeats tiles in another order. section puts the tile under a
## heading; on_tap is a Callable a tap runs first, for switches.
func _entries() -> Array[Dictionary]:
	return []


## Override: the picked tile's details: name, text, info, and buttons, each [text, Callable,
## usable].
func _details(_id: StringName) -> Dictionary:
	return {}


func open() -> void:
	_tab = _first_tab()
	_picked = &""
	super()


func _refresh() -> void:
	if not visible:
		return
	_title.text = _menu_title()
	_fill_tabs()
	var shown := _entries().filter(func(e: Dictionary) -> bool:
		return e["kind"] == _tab or (_tab == ALL and not e.get("only_in_tab", false)))
	if not _keep_picked and not shown.any(func(e: Dictionary) -> bool: return e["id"] == _picked):
		_picked = shown[0]["id"] if not shown.is_empty() else &""
	_fill_grid(shown)
	_fill_details()


func _fill_tabs() -> void:
	_clear(_tabs)
	for tab_name in _tab_list():
		var button := Button.new()
		button.text = tab_name
		button.add_theme_font_size_override("font_size", 16)
		button.custom_minimum_size = Vector2(0, 26)
		button.modulate = PICKED_COLOR if tab_name == _tab else Color.WHITE
		button.pressed.connect(func() -> void:
			_tab = tab_name
			_refresh())
		_tabs.add_child(button)


func _fill_grid(shown: Array) -> void:
	_clear(_list)
	_tiles.clear()
	var words: PackedStringArray = []
	var grid: GridContainer = null
	var section := "-"
	for entry: Dictionary in shown:
		# A new section starts a heading and a new grid, so different kinds of tiles never mix.
		if grid == null or entry.get("section", "") != section:
			section = entry.get("section", "")
			if not section.is_empty():
				var heading := Label.new()
				heading.text = section
				heading.add_theme_font_size_override("font_size", 16)
				heading.modulate = Color(1.0, 0.9, 0.6)
				_list.add_child(heading)
			grid = _new_grid()
		var tile := Button.new()
		tile.icon = entry["icon"]
		tile.expand_icon = true
		tile.custom_minimum_size = TILE_SIZE
		tile.text = entry.get("count", "")
		tile.add_theme_font_size_override("font_size", 16)
		if entry["id"] == _picked:
			tile.modulate = PICKED_COLOR
		elif entry.get("dim", false):
			tile.modulate = DIM_COLOR
		var id: StringName = entry["id"]
		var on_tap: Callable = entry.get("on_tap", Callable())
		tile.pressed.connect(func() -> void:
			# A switch flips with one tap, and its details show too.
			if on_tap.is_valid():
				on_tap.call()
			_picked = id
			_refresh())
		grid.add_child(tile)
		_tiles.append(tile)
		words.append(String(id))
	tiles_text = ", ".join(words)


func _new_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	_list.add_child(grid)
	return grid


func _fill_details() -> void:
	_clear(_detail_buttons)
	var detail := _details(_picked) if _picked != &"" else {}
	_detail_icon.texture = detail.get("icon")
	_detail_name.text = detail.get("name", "Nothing here yet")
	_detail_text.text = detail.get("text", "")
	_detail_info.text = detail.get("info", "")
	var words: PackedStringArray = [_detail_name.text, _detail_text.text, _detail_info.text]
	for spec: Array in detail.get("buttons", []):
		var button := Button.new()
		button.text = spec[0]
		button.custom_minimum_size = Vector2(DETAIL_WIDTH, BUTTON_HEIGHT)
		button.disabled = not spec[2]
		var press: Callable = spec[1]
		button.pressed.connect(func() -> void:
			_keep_picked = true
			press.call()
			_refresh()
			_keep_picked = false)
		_detail_buttons.add_child(button)
		words.append("[%s%s]" % [spec[0], "" if spec[2] else " off"])
	details_text = "\n".join(words)


## Picks a tile by id, as a tap would. For tests and for opening on one item.
func pick(id: StringName) -> void:
	_picked = id
	_refresh()


## Presses the details button with this text, as a tap would. Returns false if it's missing
## or can't be used.
func press_button(text: String) -> bool:
	for button: Button in _detail_buttons.get_children():
		if button.text == text and not button.disabled:
			button.pressed.emit()
			return true
	return false


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _focus_first_button() -> void:
	if not _tiles.is_empty():
		_tiles[0].grab_focus()
