class_name StallMenu
extends ItemGridMenu
## The stall with storage controls: everything for sale as a tile with its price, details and
## Buy buttons on the right (docs/28_...). The classic row menu (ShopMenu) stays for the older
## tests only.

## The bigger Buy button buys this many at once, or what's left today if that's fewer.
const BULK := 5


func _init() -> void:
	super()
	name = "StallMenu"
	keyboard_help = "F / Esc: close"
	touch_help = ""


func _ready() -> void:
	super()
	GameState.shop_requested.connect(func() -> void:
		if GameState.carry_mode:
			open())


func _menu_title() -> String:
	return "Stall  |  Money: %d" % Inventory.money


func _tab_names() -> Array[String]:
	return [ItemInfo.SEEDS, ItemInfo.TOOLS]


func _entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for crop in Inventory.CROPS:
		entries.append(_entry(Inventory.seed_item(crop), crop.seed_icon, crop.seed_price, _can_buy_seed(crop)))
	entries.append(_entry(&"holy_water", GameMenu.HOLY_WATER_ICON, GameState.BALANCE.holy_water_price, _can_buy_holy_water()))
	if Inventory.can_upgrade_bag():
		var price := GameState.BALANCE.bag_upgrade_price
		entries.append(_entry(&"bag_upgrade", TouchControls.BAG_ICON, price, Inventory.money >= price))
	return entries


func _entry(id: StringName, icon: Texture2D, price: int, can_buy: bool) -> Dictionary:
	return {"id": id, "icon": icon, "kind": ItemInfo.kind(id), "count": str(price), "dim": not can_buy}


func _details(id: StringName) -> Dictionary:
	if id == &"bag_upgrade":
		var price := GameState.BALANCE.bag_upgrade_price
		return {
			"icon": TouchControls.BAG_ICON,
			"name": "Bigger bag",
			"text": ItemInfo.describe(id),
			"info": "Price: %d\nNow: %d of %d kinds" % [price, Inventory.bag_slots, GameState.BALANCE.bag_max_slots],
			"buttons": [["Buy for %d" % price, _buy_bag, Inventory.money >= price and Inventory.can_upgrade_bag()]],
		}
	if id == &"holy_water":
		var holy_price := GameState.BALANCE.holy_water_price
		return _buy_details(id, GameMenu.HOLY_WATER_ICON, holy_price, Inventory.holy_water_left_today(), Inventory.buy_holy_water)
	var crop := Inventory.crop_by_id(StringName(String(id).substr(5)))
	var left := Inventory.seeds_left_today(crop) if crop.daily_stock > 0 else -1
	return _buy_details(id, crop.seed_icon, crop.seed_price, left, Inventory.buy_seed.bind(crop))


## Price, how many are owned, and stock left today when the stall limits it (-1 for no limit).
func _buy_details(id: StringName, icon: Texture2D, price: int, left: int, buy: Callable) -> Dictionary:
	var info := "Price: %d\nYou have: %d" % [price, Inventory.total(id)]
	if left >= 0:
		info += "\nLeft today: %d" % left
	var stock := BULK if left < 0 else mini(BULK, left)
	var buttons: Array = [["Buy 1 for %d" % price, _buy.bind(buy, 1), Inventory.money >= price and left != 0]]
	if stock > 1:
		buttons.append(["Buy %d for %d" % [stock, price * stock], _buy.bind(buy, stock), Inventory.money >= price * stock])
	return {"icon": icon, "name": Inventory.item_name(id), "text": ItemInfo.describe(id), "info": info, "buttons": buttons}


func _buy(buy: Callable, count: int) -> void:
	for i in count:
		if not buy.call():
			return
		Audio.play(&"buy")


func _buy_bag() -> void:
	if Inventory.upgrade_bag():
		Audio.play(&"buy")


func _can_buy_seed(crop: CropData) -> bool:
	return Inventory.money >= crop.seed_price and (crop.daily_stock <= 0 or Inventory.seeds_left_today(crop) > 0)


func _can_buy_holy_water() -> bool:
	return Inventory.money >= GameState.BALANCE.holy_water_price and Inventory.holy_water_left_today() > 0
