extends GameMenu
## The bag: everything the player owns on one screen. Key I opens and closes it.

const SWORD_ICON := preload("res://assets/objects/sword.png")
const HOE_ICON := preload("res://assets/items/purifying_hoe.png")

## Everything listed, one per line.
var items_text := ""

@onready var crops_grid: GridContainer = $Margin/Box/Crops
@onready var items_grid: GridContainer = $Margin/Box/Items


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
	_clear(crops_grid)
	_clear(items_grid)
	crops_grid.add_child(Control.new())
	_add_label(crops_grid, "")
	_add_label(crops_grid, "Harvested")
	crops_grid.add_child(Control.new())
	_add_label(crops_grid, "Seeds")
	for crop in Inventory.CROPS:
		# Ward plants are never harvested, so they go in the item list below.
		if crop.burst_radius > 0:
			continue
		crops_grid.add_child(_icon(crop.icon))
		_add_label(crops_grid, crop.display_name)
		_add_label(crops_grid, str(Inventory.harvest_count(crop)))
		crops_grid.add_child(_icon(crop.seed_icon))
		_add_label(crops_grid, str(Inventory.seed_count(crop)))
	var lines: PackedStringArray = []
	lines.append(_add_item(HOLY_WATER_ICON, "Holy water: %d" % Inventory.holy_water))
	if Inventory.strong_holy_water > 0:
		lines.append(_add_item(STRONG_WATER_ICON, "Strong holy water: %d" % Inventory.strong_holy_water))
	for crop in Inventory.CROPS:
		if crop.burst_radius > 0 and Inventory.seed_count(crop) > 0:
			lines.append(_add_item(crop.seed_icon, "%s seeds: %d" % [crop.display_name, Inventory.seed_count(crop)]))
	for material in Inventory.MATERIALS:
		lines.append(_add_item(material.icon, "%s: %d" % [material.display_name, Inventory.material_count(material)]))
	for building in Inventory.BUILDINGS:
		if Inventory.building_count(building) > 0:
			lines.append(_add_item(building.preview_texture, "%s: %d" % [building.display_name, Inventory.building_count(building)]))
	if Inventory.has_sword:
		lines.append(_add_item(SWORD_ICON, "Sword"))
	if Inventory.has_purifying_hoe:
		lines.append(_add_item(HOE_ICON, "Hoe: %d of %d left" % [Inventory.hoe_uses_left, GameState.BALANCE.hoe_daily_uses]))
	items_text = "\n".join(lines)


func _clear(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.free()


func _add_item(icon: Texture2D, text: String) -> String:
	items_grid.add_child(_icon(icon))
	_add_label(items_grid, text)
	return text


func _add_label(parent: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
