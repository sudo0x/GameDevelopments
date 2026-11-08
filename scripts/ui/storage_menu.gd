class_name StorageMenu
extends ItemGridMenu
## Storage controls (docs/28_...): the storage chest. Every kind of item owned as a tile; the
## details say how many are in the bag and in the chest, with Take and Put buttons.

## Every item in words, for tests.
var rows_text := ""


func _init() -> void:
	super()
	name = "StorageMenu"
	keyboard_help = "F / Esc: close"
	touch_help = ""


func _ready() -> void:
	super()
	GameState.storage_requested.connect(open)


func _menu_title() -> String:
	return "Storage  |  Bag: %d of %d kinds" % [Inventory.used_slots(), Inventory.bag_slots]


func _tab_names() -> Array[String]:
	return [ItemInfo.SEEDS, ItemInfo.CROPS, ItemInfo.TOOLS, ItemInfo.BUILD, ItemInfo.WEAPONS, ItemInfo.MATERIALS]


func _entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var lines: PackedStringArray = []
	for item in Inventory.all_items():
		if Inventory.total(item) <= 0:
			continue
		entries.append({
			"id": item,
			"icon": KeyToolBar.item_icon(item),
			"kind": ItemInfo.kind(item),
			"count": str(Inventory.total(item)) if item not in [&"hoe", &"can", &"sword", &"bow"] else "",
		})
		lines.append("%s: bag %d, stored %d" % [Inventory.item_name(item), Inventory.carried(item), Inventory.stored(item)])
	rows_text = "\n".join(lines)
	return entries


func _details(id: StringName) -> Dictionary:
	var stored := Inventory.stored(id)
	var room := Inventory.has_room_for(id)
	var buttons: Array = []
	if Inventory.total(id) > 1:
		buttons.append(["Take 1", Inventory.take.bind(id, 1), stored > 0 and room])
	buttons.append(["Take all", Inventory.take.bind(id, -1), stored > 0 and room])
	buttons.append(["Put all", Inventory.put.bind(id, -1), Inventory.carried(id) > 0])
	var info := "In bag: %d\nIn chest: %d" % [Inventory.carried(id), stored]
	if stored > 0 and not room:
		info += "\nThe bag is full."
	return {
		"icon": KeyToolBar.item_icon(id),
		"name": Inventory.item_name(id),
		"text": ItemInfo.describe(id),
		"info": info,
		"buttons": buttons,
	}
