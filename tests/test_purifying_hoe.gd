extends SceneTree
## The crafted hoe: made once, heals single cursed tiles by key, a few times a day.
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
	var progress: Node = root.get_node("Progress")
	var saves: Node = root.get_node("SaveGame")
	# These checks count holy water from zero; new games start with some (test_title).
	inv.holy_water = 0
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var hud: Node = main.get_node("HUD")
	var menu: Node = main.get_node("HUD/CraftingMenu")
	var bag: Node = main.get_node("HUD/BagMenu")
	var player: Node = main.get_node("World/Player")
	var wood: Variant = inv.MATERIALS[0]
	var stone: Variant = inv.MATERIALS[1]
	var recipe: Variant = inv.RECIPES[1]

	# Before crafting, the hoe does nothing to the curse.
	check("recipe needs", menu._buttons.size() == inv.RECIPES.size() and recipe.needs.size() == 2)
	check("no hoe at the start", not inv.has_purifying_hoe)
	var edge := Vector2i(35, 12)
	check("cursed tile as expected", g.get_cell_source_id(edge) == 1)
	check("plain hoe can't heal", not farm.can_use(0, edge))
	farm.healing.purify(edge)
	check("purify refused without it", g.get_cell_source_id(edge) == 1)
	check("HUD quiet", not hud.tool_label.text.contains("Purify"))

	# Crafting it.
	inv.add_material(wood, 9)
	inv.add_material(stone, 5)
	check("9 wood isn't enough", not inv.can_craft(recipe))
	inv.add_material(wood, 3)
	check("12 wood is", inv.can_craft(recipe))
	gs.request_crafting()
	await process_frame
	check("menu text", menu._labels[1].text == "Purifying hoe\n10 Wood (12), 5 Stone (5)")
	menu._buttons[1].pressed.emit()
	check("made", inv.has_purifying_hoe and inv.hoe_uses_left == 2)
	check("spent", inv.material_count(wood) == 2 and inv.material_count(stone) == 0)
	check("menu shows it's done", menu._labels[1].text == "Purifying hoe\nUse the hoe on cursed land.")
	check("button says Made", menu._buttons[1].text == "Made" and menu._buttons[1].disabled)
	inv.add_material(wood, 20)
	inv.add_material(stone, 20)
	check("can't make a second", not inv.can_craft(recipe) and not inv.craft(recipe))
	check("nothing spent on a second", inv.material_count(wood) == 22)
	menu.close()
	await physics_frame

	# Using it, by key, on the east edge of the shore.
	player.global_position = g.to_global(g.map_to_local(Vector2i(34, 12))) + Vector2(0, 8)
	player.facing = 3
	for i in 5:
		await physics_frame
	check("facing the curse", farm.target_cell == edge)
	await press("tool_1")
	check("HUD shows uses", hud.tool_label.text == "Tool: Hoe  |  Purify left today: 2")
	check("highlight valid on curse", farm.can_use(0, edge))
	await press("use_tool")
	check("healed one tile", g.get_cell_source_id(edge) == 0)
	check("only one tile", g.get_cell_source_id(edge + Vector2i(1, 0)) == 1 and farm.healing.cleansed.size() == 1)
	check("not tilled by the same hit", not farm.is_tilled(edge))
	check("one use spent", inv.hoe_uses_left == 1)
	check("holy water untouched", inv.holy_water == 0)
	check("HUD counts down", hud.tool_label.text.ends_with(": 1"))
	await press("use_tool")
	check("second press tills the healed tile, for free", farm.is_tilled(edge) and inv.hoe_uses_left == 1)

	# Healing still does everything else.
	inv.hoe_uses_left = 5
	var money0: int = inv.money
	farm.healing.purify(Vector2i(38, 10))
	check("digs up finds", inv.money == money0 + 40)
	farm.healing.purify(Vector2i(44, 12))
	check("reveals trees", farm.gathering.spots[Vector2i(44, 12)].revealed)
	await physics_frame
	var fx: Array = farm.healing.get_children().filter(func(n: Node) -> bool: return n.scene_file_path.ends_with("cleanse_effect.tscn"))
	check("plays the effect", fx.size() >= 1)
	farm.healing.purify(Vector2i(0, 13))
	check("outer ring safe", g.get_cell_source_id(Vector2i(0, 13)) == 1 and inv.hoe_uses_left == 3)

	# The daily limit.
	inv.hoe_uses_left = 1
	farm.healing.purify(Vector2i(40, 3))
	check("last use works", g.get_cell_source_id(Vector2i(40, 3)) == 0 and inv.hoe_uses_left == 0)
	check("no uses, not usable", not farm.can_use(0, Vector2i(41, 3)))
	farm.healing.purify(Vector2i(41, 3))
	check("no uses, no healing", g.get_cell_source_id(Vector2i(41, 3)) == 1)
	progress.end_day()
	check("full again in the morning", inv.hoe_uses_left == 2)

	bag.open()
	check("bag shows it", bag.items_text.contains("Purifying hoe: 2 of 2"))
	bag.close()

	# Saved, with full uses after loading.
	inv.hoe_uses_left = 1
	saves.save_game()
	inv.has_purifying_hoe = false
	saves.load_game()
	check("hoe saved", inv.has_purifying_hoe)
	check("full uses after a reload", inv.hoe_uses_left == 2)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
