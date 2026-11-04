extends GameMenu
## The bag: everything the player owns on one screen. Key I opens and closes it.

const COLUMNS: Array[String] = ["", "Harvested", "Seeds"]

@onready var crops_grid: GridContainer = $Margin/Box/Crops
@onready var items_label: Label = $Margin/Box/Items


func _unhandled_input(event: InputEvent) -> void:
	if not visible and not get_tree().paused and event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		open()
	else:
		super(event)


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
	for building in GameState.BUILDINGS:
		if GameState.building_count(building) > 0:
			lines.append("%s: %d" % [building.display_name, GameState.building_count(building)])
	if GameState.has_sword:
		lines.append("Sword")
	if GameState.has_purifying_hoe:
		lines.append("Purifying hoe: %d of %d left today" % [GameState.hoe_uses_left, GameState.BALANCE.hoe_daily_uses])
	items_label.text = "\n".join(lines)


func _add_cell(text: String) -> void:
	var label := Label.new()
	label.text = text
	crops_grid.add_child(label)
