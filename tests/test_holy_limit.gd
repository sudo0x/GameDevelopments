extends SceneTree
## The stall sells a limited amount of holy water each day, so money alone can't beat the curse.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var saves: Node = root.get_node("SaveGame")
	inv.money = 1000
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var shop: Control = main.get_node("HUD/ShopMenu")
	var start: int = inv.holy_water
	var last: int = shop._labels.size() - 1
	shop._refresh()
	check("the day starts with 3 for sale", inv.holy_water_left_today() == 3)
	check("the shop shows it", shop._labels[last].text.contains("3 left"))
	check("buying 1", inv.buy_holy_water())
	check("buying 2", inv.buy_holy_water())
	check("buying 3", inv.buy_holy_water())
	var money: int = inv.money
	check("a fourth is refused", not inv.buy_holy_water())
	check("a refused sale costs nothing", inv.money == money and inv.holy_water == start + 3)
	shop._refresh()
	check("the shop says sold out", shop._buttons[last].text == "Sold out" and shop._buttons[last].disabled)
	check("seeds can still be bought", not shop._buttons[0].disabled)

	progress.end_day()
	shop._refresh()
	check("the stall refills in the morning", inv.holy_water_left_today() == 3)
	check("the button is back", shop._buttons[last].text.begins_with("Buy") and not shop._buttons[last].disabled)
	inv.buy_holy_water()
	saves.start_new_game()
	check("a new game starts with a full stall", inv.holy_water_left_today() == 3)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
