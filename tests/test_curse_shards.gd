extends SceneTree
## Creatures drop curse shards, which make strong holy water, which heals a 5×5 patch.
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


func spawn(main: Node, at: Vector2) -> Node2D:
	var shade: Node2D = load("res://scenes/creatures/creature.tscn").instantiate()
	shade.data = load("res://data/creatures/shade.tres")
	shade.position = at
	main.get_node("World").add_child(shade)
	return shade


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var inv: Node = root.get_node("Inventory")
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
	var player: Node2D = main.get_node("World/Player")
	var menu: Node = main.get_node("HUD/CraftingMenu")
	var shard = inv.MATERIALS[2]
	var recipe = inv.RECIPES[6]
	player._safe_left = 9999.0

	# Drops.
	check("no shards yet", inv.material_count(shard) == 0)
	var shade := spawn(main, Vector2(600, 500))
	await physics_frame
	shade.take_hit(1, Vector2.RIGHT)
	check("no drop until defeated", inv.material_count(shard) == 0)
	shade.take_hit(1, Vector2.RIGHT)
	check("one shard", inv.material_count(shard) == 1)
	check("notice", hud.notice_label.text == "+1 Curse shard")
	shade.take_hit(1, Vector2.RIGHT)
	check("no second drop", inv.material_count(shard) == 1)
	var other := spawn(main, Vector2(620, 500))
	await physics_frame
	other.take_hit(5, Vector2.RIGHT)
	check("a big hit still drops one", inv.material_count(shard) == 2)

	# Crafting.
	gs.request_crafting()
	await process_frame
	check("menu row", menu._labels[6].text == "Strong holy water\n1 Holy water (0), 2 Curse shard (2)")
	check("needs holy water", menu._buttons[6].disabled)
	inv.holy_water = 2
	check("now it can be made", inv.can_craft(recipe))
	menu._buttons[6].pressed.emit()
	check("made", inv.strong_holy_water == 1)
	check("spent", inv.holy_water == 1 and inv.material_count(shard) == 0)
	check("can't make another", menu._buttons[6].disabled)
	menu.close()

	# Choosing it with Q and E, by key.
	await press("tool_5")
	check("normal first", not player.strong_water)
	check("label hints at the choice", hud.tool_label.text == "Tool: Holy water: 1  (Q / E to change)")
	await press("seed_next")
	check("E picks strong", player.strong_water)
	check("label", hud.tool_label.text == "Tool: Strong holy water: 1  (Q / E to change)")
	await press("seed_prev")
	check("Q goes back", not player.strong_water)
	await press("tool_3")
	await press("seed_next")
	check("seeds still change with the Seeds tool", player.seed_index == 1 and not player.strong_water)
	await press("tool_5")
	await press("seed_next")

	# Using it by key from the shore.
	player.global_position = g.to_global(g.map_to_local(Vector2i(34, 12))) + Vector2(0, 8)
	player.facing = 3
	for i in 5:
		await physics_frame
	var target: Vector2i = farm.target_cell
	check("usable on the curse", farm.can_use(4, target))
	var before: int = farm.healing.cleansed.size()
	await press("use_tool")
	check("one used", inv.strong_holy_water == 0 and inv.holy_water == 1)
	var healed: int = farm.healing.cleansed.size() - before
	print("healed %d tiles by key" % healed)
	check("more than a 3x3 could", healed > 9)
	check("not usable with none", not farm.can_use(4, target + Vector2i(6, 0)))

	# A full 5×5, and the rules still hold.
	inv.strong_holy_water = 3
	before = farm.healing.cleansed.size()
	farm.healing.cleanse(Vector2i(40, 3), true)
	check("exactly 5x5", farm.healing.cleansed.size() - before == 25)
	check("corner healed", g.get_cell_source_id(Vector2i(42, 5)) == 0)
	check("one past stays cursed", g.get_cell_source_id(Vector2i(43, 3)) == 1)
	before = inv.strong_holy_water
	farm.healing.cleanse(Vector2i(20, 13), true)
	check("free on clean land", inv.strong_holy_water == before)
	farm.healing.cleanse(Vector2i(1, 1), true)
	check("the outer ring is safe", g.get_cell_source_id(Vector2i(0, 1)) == 1 and g.get_cell_source_id(Vector2i(1, 0)) == 1)

	# Normal holy water is unchanged.
	inv.holy_water = 1
	before = farm.healing.cleansed.size()
	farm.healing.cleanse(Vector2i(50, 2))
	check("normal stays 3x3", farm.healing.cleansed.size() - before == 9)

	# Saved.
	inv.strong_holy_water = 4
	inv.materials[shard.id] = 3
	saves.save_game()
	inv.strong_holy_water = 0
	inv.materials.clear()
	saves.load_game()
	check("saved", inv.strong_holy_water == 4 and inv.material_count(shard) == 3)
	var bag: Node = main.get_node("HUD/BagMenu")
	bag.open()
	check("bag shows both", bag.items_text.contains("Strong holy water: 4") and bag.items_text.contains("Curse shard: 3"))
	bag.close()
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
