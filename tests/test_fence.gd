extends SceneTree
## The fence: a second building, picked with Q and E, that joins up and blocks walking.
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
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var hud: Node = main.get_node("HUD")
	var player: Node = main.get_node("World/Player")
	var fence = gs.building_by_id(&"fence")
	check("fence exists", fence != null and fence.heal_radius == 0)

	# Crafting by wood alone.
	gs.add_material(gs.MATERIALS[0], 6)
	var recipe = gs.RECIPES[3]
	check("recipe is the fence", recipe.building == fence)
	for i in 6:
		gs.craft(recipe)
	check("6 made", gs.building_count(fence) == 6 and gs.material_count(gs.MATERIALS[0]) == 0)

	# Q and E go through the buildings, and wrap around.
	await press("tool_6")
	check("starts on the lantern", player.selected_building().id == &"lantern_post")
	await press("seed_next")
	check("E picks the fence", player.selected_building() == fence)
	await physics_frame
	await physics_frame
	check("preview changes", farm.build_preview.texture == fence.preview_texture)
	check("label changes", hud.tool_label.text == "Tool: Build  |  Fence: 6  (Q / E to change)")
	await press("seed_next")
	check("wraps around", player.selected_building().id == &"lantern_post")
	await press("seed_prev")
	check("Q goes back", player.selected_building() == fence)

	# A row of fences, side by side.
	var y := 12
	for x in range(14, 18):
		farm.builder.place(Vector2i(x, y), fence)
	check("4 placed", farm.builder.placed.size() == 4 and gs.building_count(fence) == 2)
	var first: Node2D = farm.builder.placed[Vector2i(14, y)]["node"]
	var second: Node2D = farm.builder.placed[Vector2i(15, y)]["node"]
	check("exactly one tile apart", second.global_position.x - first.global_position.x == 32.0)
	var sprite: Sprite2D = first.get_node("Sprite2D")
	check("art fills the tile", sprite.texture.get_width() == 32)
	await physics_frame
	await physics_frame
	check("next tile still free", farm.can_build(Vector2i(18, y)))

	# No gaps to squeeze through.
	var mid: Vector2 = (first.global_position + second.global_position) / 2.0
	player.global_position = mid + Vector2(0, 24)
	for i in 3:
		await physics_frame
	Input.action_press("move_up")
	for i in 60:
		await physics_frame
	Input.action_release("move_up")
	check("no gap between sections", player.global_position.y > first.global_position.y)

	# Picking up gives a fence back, not a lantern.
	farm.builder.pick_up(Vector2i(14, y))
	check("fence back in the bag", gs.building_count(fence) == 3)

	# Fences don't heal.
	var healed: int = farm.healing.cleansed.size()
	farm.builder.place(Vector2i(34, 13), fence)
	gs.end_day()
	check("no healing from fences", farm.healing.cleansed.size() == healed)
	check("saved with its id", gs.farm_state["buildings"].filter(func(b: Dictionary) -> bool: return b["id"] == &"fence").size() == 4)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
