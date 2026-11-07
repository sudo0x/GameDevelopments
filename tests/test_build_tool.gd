extends SceneTree
## The Build tool: key 6, choosing with Q and E, and where the preview says a building can go.
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


## Stands one tile left of a cell, facing it.
func aim_at(player: Node, g: TileMapLayer, cell: Vector2i) -> void:
	player.global_position = g.to_global(g.map_to_local(cell + Vector2i(-1, 0))) + Vector2(0, 8)
	player.facing = 3
	for i in 5:
		await physics_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var saves: Node = root.get_node("SaveGame")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var hud: Node = main.get_node("HUD")
	var player: Node = main.get_node("World/Player")
	var preview: Sprite2D = farm.build_preview
	var lantern = inv.BUILDINGS[0]
	var BUILD := 5

	var key := InputEventKey.new()
	key.physical_keycode = KEY_6
	key.pressed = true
	check("physical 6 maps to tool_6", key.is_action_pressed("tool_6"))
	check("no preview at the start", not preview.visible)
	await press("tool_6")
	await physics_frame
	check("key 6 selects Build", player.tool == BUILD)
	check("preview shows", preview.visible and preview.texture == lantern.preview_texture)
	check("tool label", hud.tool_label.text == "Tool: Build  |  Lantern post: 0  (Q / E to change)")

	# With none crafted, nothing can be placed anywhere.
	var open_cell := Vector2i(16, 12)
	await aim_at(player, g, open_cell)
	check("spot is free", farm.can_build(open_cell))
	check("no building, no placing", not farm.can_use(BUILD, open_cell))
	check("preview red", preview.modulate == preview.INVALID_COLOR)

	# Crafting one.
	var recipe = inv.RECIPES[2]
	inv.add_material(inv.MATERIALS[0], 3)
	inv.add_material(inv.MATERIALS[1], 2)
	check("recipe is the lantern", recipe.building == lantern)
	check("crafted", inv.craft(recipe) and inv.building_count(lantern) == 1)
	check("materials spent", inv.material_count(inv.MATERIALS[0]) == 0 and inv.material_count(inv.MATERIALS[1]) == 0)
	check("can make more than one", not inv.already_made(recipe))
	await physics_frame
	await physics_frame
	check("usable now", farm.can_use(BUILD, open_cell))
	check("preview green", preview.modulate == preview.VALID_COLOR)
	check("preview on the target tile", preview.position == g.map_to_local(open_cell) + farm.BUILDING_BASE)
	check("label counts it", hud.tool_label.text.contains("Lantern post: 1"))

	# Q and E pick buildings here, and seeds elsewhere.
	await press("seed_next")
	check("seed unchanged while building", player.seed_index == 0)
	await press("tool_3")
	await press("seed_next")
	check("seed changes with the Seeds tool", player.seed_index == 1)
	await press("tool_6")
	await physics_frame
	await press("tool_1")
	await physics_frame
	await physics_frame
	check("preview hides with another tool", not preview.visible)
	await press("tool_6")

	# Places that must be refused.
	check("cursed land", not farm.can_build(Vector2i(38, 13)))
	check("off the map", not farm.can_build(Vector2i(200, 13)))
	farm.till(open_cell)
	check("tilled soil", not farm.can_build(open_cell))
	check("a tree", not farm.can_build(Vector2i(22, 6)))
	check("a rock", not farm.can_build(Vector2i(18, 7)))
	for i in 3:
		farm.gathering.hit(Vector2i(18, 7))
	await physics_frame
	check("rubble: the rock will grow back", not farm.can_build(Vector2i(18, 7)))
	for path in ["House", "ShippingBox", "ShopStall", "Workbench", "LanternDoor", "Shrine"]:
		var thing: Node2D = main.get_node("World/" + path)
		check(path + " itself", not farm.can_build(g.local_to_map(g.to_local(thing.global_position + Vector2(0, -5)))))
	var door: Node2D = main.get_node("World/House/Door")
	check("in front of the door", not farm.can_build(g.local_to_map(g.to_local(door.global_position))))
	var box: Node2D = main.get_node("World/ShippingBox")
	check("next to the box stays clear", not farm.can_build(g.local_to_map(g.to_local(box.global_position + Vector2(0, -10))) + Vector2i(1, 0)))
	var stand := Vector2i(16, 16)
	player.global_position = g.to_global(g.map_to_local(stand))
	for i in 4:
		await physics_frame
	check("the tile the player stands on", not farm.can_build(stand))
	check("a free tile nearby is fine", farm.can_build(stand + Vector2i(3, 0)))

	# Crafted buildings show in the bag and are saved.
	var bag: Node = main.get_node("HUD/BagMenu")
	bag.open()
	check("bag shows it", bag.items_text.contains("Lantern post: 1"))
	bag.close()
	saves.save_game()
	inv.buildings.clear()
	saves.load_game()
	check("saved", inv.building_count(lantern) == 1)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
