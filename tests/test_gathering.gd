extends SceneTree
## Trees and rocks: hitting them by key, what they leave, and healing to reveal them.
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


func stand_left_of(player: Node, g: TileMapLayer, cell: Vector2i) -> void:
	player.global_position = g.to_global(g.map_to_local(cell + Vector2i(-1, 0))) + Vector2(0, 8)
	player.facing = 3
	for i in 5:
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
	var gather: Node = farm.gathering
	var wood = gs.MATERIALS[0]
	var stone = gs.MATERIALS[1]

	# Every spot is placed sensibly.
	check("15 spots", gather.spots.size() == 15)
	var shore := 0
	var cursed := 0
	var on_finds := false
	for cell: Vector2i in gather.spots:
		var spot: Node2D = gather.spots[cell]
		check("spot %s revealed only on clean land" % str(cell), spot.revealed == (g.get_cell_source_id(cell) == 0))
		check("spot %s is in the y-sorted World" % str(cell), spot.get_parent().name == "World")
		on_finds = on_finds or farm.healing.finds.has(cell)
		if spot.revealed:
			shore += 1
		else:
			cursed += 1
	check("some to gather from the start", shore == 8)
	check("some hidden in the curse", cursed == 7)
	check("none on a buried find", not on_finds)

	# Chop a tree, by key.
	var tree_cell := Vector2i(22, 6)
	await stand_left_of(player, g, tree_cell)
	check("facing the tree", farm.target_cell == tree_cell)
	check("status names it", hud.crop_status_label.text == "Tree: press 4, then Space to gather.")
	await press("tool_1")
	await press("use_tool")
	check("the hoe does nothing to a tree", gather.spots[tree_cell].hits_left == 3 and not farm.is_tilled(tree_cell))
	await press("tool_4")
	await press("use_tool")
	await press("use_tool")
	check("no wood yet", gs.material_count(wood) == 0 and gather.spots[tree_cell].hits_left == 1)
	await press("use_tool")
	check("3 wood", gs.material_count(wood) == 3)
	check("notice", hud.notice_label.text == "+3 Wood")
	var tree: Node2D = gather.spots[tree_cell]
	check("stump now", tree.gathered and tree.sprite.texture == tree.data.remains_texture)
	await press("use_tool")
	check("stump gives nothing", gs.material_count(wood) == 3)
	await physics_frame
	await physics_frame
	check("stump says when it returns", hud.crop_status_label.text == "Tree: grows back in 5 days.")
	check("can't till a stump", not farm.can_use(0, tree_cell))
	Input.action_press("move_right")
	for i in 60:
		await physics_frame
	Input.action_release("move_right")
	check("stump still blocks", player.global_position.x < tree.global_position.x)

	# Rocks leave rubble you can walk over.
	var rock_cell := Vector2i(18, 7)
	await stand_left_of(player, g, rock_cell)
	await press("use_tool")
	await press("use_tool")
	await press("use_tool")
	check("2 stone", gs.material_count(stone) == 2)
	var rock: Node2D = gather.spots[rock_cell]
	for i in 3:
		await physics_frame
	Input.action_press("move_right")
	for i in 40:
		await physics_frame
	Input.action_release("move_right")
	check("walks over rubble", player.global_position.x > rock.global_position.x)
	check("rubble cell can be farmed", farm.can_use(0, rock_cell))

	# A tree fades while the player is behind it, not in front of it.
	var shade: Node2D = gather.spots[Vector2i(14, 7)]
	player.global_position = shade.global_position + Vector2(20, -8)
	for i in 3:
		await physics_frame
	check("see-through from behind", shade.sprite.modulate.a < 1.0)
	player.global_position = shade.global_position + Vector2(20, 24)
	for i in 3:
		await physics_frame
	check("solid again in front", shade.sprite.modulate.a == 1.0)

	# Hidden until healed.
	var hidden := Vector2i(44, 12)
	var buried: Node2D = gather.spots[hidden]
	check("hidden in the curse", not buried.visible and not gather.can_hit(hidden))
	check("no status when hidden", gather.status(hidden) == "")
	gs.holy_water = 3
	farm.healing.cleanse(hidden)
	await physics_frame
	await physics_frame
	check("healing reveals it", buried.revealed and buried.visible and gather.can_hit(hidden))
	check("revealed tree is solid", not buried.shape.disabled)
	check("can't till under it", not farm.can_use(0, hidden))
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
