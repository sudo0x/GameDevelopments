extends SceneTree
## The workbench menu, and crafting by real key presses.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await physics_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	Input.flush_buffered_events()
	await physics_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var inv: Node = root.get_node("Inventory")
	# These checks count holy water from zero; new games start with some (test_title).
	inv.holy_water = 0
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var player: Node = main.get_node("World/Player")
	var bench: Node2D = main.get_node("World/Workbench")
	var menu: Control = main.get_node("HUD/CraftingMenu")
	var bag: Control = main.get_node("HUD/BagMenu")
	var recipe: Variant = inv.RECIPES[0]
	var radish: Variant = inv.CROPS[0]
	var stone: Variant = inv.MATERIALS[1]
	var cell: Vector2i = g.local_to_map(g.to_local(bench.global_position + Vector2(0, -5)))
	check("stands on grass", g.get_cell_source_id(cell) == 0)
	check("can't till under it", not farm.can_use(0, cell))

	for offset: Variant in [Vector2(0, 16), Vector2(-44, -6), Vector2(44, -6), Vector2(0, -22)]:
		player.global_position = bench.global_position + offset
		for i in 6:
			await physics_frame
		await press("interact")
		check("opens from %s" % str(offset), menu.visible and paused)
		await press("interact")
		check("F closes", not menu.visible and not paused)

	player.global_position = bench.global_position + Vector2(0, 16)
	for i in 6:
		await physics_frame
	await press("interact")
	check("lists the recipe", menu._labels[0].text == "Holy water\n1 Radish (0), 1 Stone (0)")
	check("can't make it yet", menu._buttons[0].disabled)
	menu._buttons[0].pressed.emit()
	check("nothing made", inv.holy_water == 0)
	await press("ui_cancel")
	check("Esc closes", not menu.visible)

	inv.harvest[&"radish"] = 5
	inv.add_material(stone, 2)
	await press("interact")
	check("shows what you have", menu._labels[0].text == "Holy water\n1 Radish (5), 1 Stone (2)")
	check("button on and focused", not menu._buttons[0].disabled and menu._buttons[0].has_focus())
	await press("ui_accept")
	check("Enter makes one", inv.holy_water == 1)
	check("ingredients used", inv.harvest_count(radish) == 4 and inv.material_count(stone) == 1)
	check("row updates", menu._labels[0].text == "Holy water\n1 Radish (4), 1 Stone (1)")
	menu._buttons[0].pressed.emit()
	check("second made", inv.holy_water == 2 and inv.harvest_count(radish) == 3 and inv.material_count(stone) == 0)
	check("disabled when short", menu._buttons[0].disabled)
	menu._buttons[0].pressed.emit()
	check("third refused", inv.holy_water == 2 and inv.harvest_count(radish) == 3)
	await press("inventory")
	check("bag won't open over it", not bag.visible and menu.visible)
	await press("interact")

	# The leftovers still behave normally.
	inv.ship_all()
	check("leftover ships", inv.shipped.get(&"radish", 0) == 3)
	check("value right", inv.shipped_value() == radish.sell_price * 3)
	check("crafting costs less than the shop", radish.sell_price < gs.BALANCE.holy_water_price)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
