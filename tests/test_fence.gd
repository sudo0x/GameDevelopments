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
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
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
	var fence = inv.building_by_id(&"fence")
	check("fence exists", fence != null and fence.heal_radius == 0)

	# Crafting by wood alone.
	inv.add_material(inv.MATERIALS[0], 6)
	var recipe = inv.RECIPES[3]
	check("recipe is the fence", recipe.building == fence)
	for i in 6:
		inv.craft(recipe)
	check("6 made", inv.building_count(fence) == 6 and inv.material_count(inv.MATERIALS[0]) == 0)

	# Q and E go through the buildings, and wrap around.
	await press("tool_6")
	check("starts on the lantern", player.selected_building().id == &"lantern_post")
	await press("seed_next")
	check("E picks the fence", player.selected_building() == fence)
	await physics_frame
	await physics_frame
	check("preview changes", farm.build_preview.texture == fence.preview_texture)
	check("label changes", hud.tool_label.text == "Tool: Build  |  Fence: 6  (Q / E to change)")
	await press("seed_prev")
	await press("seed_prev")
	# The map's own kinds (shipping box, workbench, old lantern) are skipped while the bag has none.
	check("Q wraps around to the last craftable one", player.selected_building().id == &"well")
	await press("seed_next")
	await press("seed_next")
	check("E goes back", player.selected_building() == fence)

	# A row of fences, side by side.
	var y := 12
	for x in range(14, 18):
		farm.builder.place(Vector2i(x, y), fence)
	check("4 placed", farm.builder.to_state().size() == 4 and inv.building_count(fence) == 2)
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
	check("fence back in the bag", inv.building_count(fence) == 3)

	# Fences don't heal.
	var healed: int = farm.healing.cleansed.size()
	farm.builder.place(Vector2i(34, 13), fence)
	progress.end_day()
	check("no healing from fences", farm.healing.cleansed.size() == healed)
	check("saved with its id", saves.farm_state["buildings"].filter(func(b: Dictionary) -> bool: return b["id"] == &"fence").size() == 4)

	# A line going up and down uses the vertical art, and has no gaps either.
	inv.add_building(fence, 3)
	for row in range(8, 11):
		farm.builder.place(Vector2i(10, row), fence)
	var top: Node = farm.builder.placed[Vector2i(10, 8)]["node"]
	var middle: Node = farm.builder.placed[Vector2i(10, 9)]["node"]
	check("a vertical line uses the vertical art", middle.vertical and top.vertical and middle.get_node("Sprite2D").texture == middle.VERTICAL_TEXTURE)
	check("a row stays side-on", not second.vertical and second.get_node("Sprite2D").texture == second.SIDE_TEXTURE)
	check("a lone fence is side-on", not farm.builder.placed[Vector2i(34, 13)]["node"].vertical)
	check("each fence has its own shape", (middle.get_node("Shape").shape as RectangleShape2D).size.y == 32.0 and (second.get_node("Shape").shape as RectangleShape2D).size.y == 8.0)
	await physics_frame
	await physics_frame
	player.global_position = Vector2(middle.global_position.x + 24, middle.global_position.y - 12)
	for i in 3:
		await physics_frame
	Input.action_press("move_left")
	for i in 60:
		await physics_frame
	Input.action_release("move_left")
	check("no gap in the vertical line", player.global_position.x > middle.global_position.x)
	# Taking the middle one leaves two loners, which go back to side-on.
	farm.builder.pick_up(Vector2i(10, 9))
	check("neighbors refit when one is picked up", not top.vertical)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
