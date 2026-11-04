extends PanelContainer
## The bag: everything the player owns on one screen. Key I opens and closes it.
## The game pauses while it's open; this node keeps running (process_mode = Always).

const COLUMNS: Array[String] = ["", "Harvested", "Seeds"]

@onready var crops_grid: GridContainer = $Margin/Box/Crops
@onready var items_label: Label = $Margin/Box/Items


func _ready() -> void:
	GameState.inventory_changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if visible:
			close()
		elif not get_tree().paused:
			open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open() -> void:
	show()
	_refresh()
	get_tree().paused = true


func close() -> void:
	hide()
	get_tree().paused = false


## Skipped while closed: open() refreshes anyway, so there's no need to rebuild the list.
func _refresh() -> void:
	if not visible:
		return
	for child in crops_grid.get_children():
		child.free()
	for heading in COLUMNS:
		_add_cell(heading)
	for crop in GameState.CROPS:
		_add_cell(crop.display_name)
		_add_cell(str(GameState.harvest_count(crop)))
		_add_cell(str(GameState.seed_count(crop)))
	var lines: PackedStringArray = ["Holy water: %d" % GameState.holy_water]
	for material in GameState.MATERIALS:
		lines.append("%s: %d" % [material.display_name, GameState.material_count(material)])
	items_label.text = "\n".join(lines)


func _add_cell(text: String) -> void:
	var label := Label.new()
	label.text = text
	crops_grid.add_child(label)
