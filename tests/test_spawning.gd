extends SceneTree
## Creatures rise near the curse each morning, by the rules, and vanish at night.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func alive(spawner: Node) -> Array:
	return spawner.creatures.filter(func(c: Node) -> bool: return is_instance_valid(c) and not c.is_queued_for_deletion())


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
	var player: Node2D = main.get_node("World/Player")
	var spawner: Node = farm.spawner
	player._safe_left = 9999.0
	check("none on day 1", alive(spawner).is_empty())
	gs.end_day()
	check("none on day 2", alive(spawner).is_empty())
	gs.end_day()
	check("they start on day 3", alive(spawner).size() == 2)
	check("a warning the first time", hud.notice_label.text == "Something stirs at the edge of the curse...")
	await process_frame

	# Where they appear, checked over several mornings.
	var ok_edge := true
	var ok_light := true
	var ok_player := true
	var ok_spacing := true
	var ok_reachable := true
	var seen_spots := {}
	for morning in 12:
		var list := alive(spawner)
		check("morning %d count" % morning, list.size() == 2)
		for a: Node2D in list:
			seen_spots[a.global_position] = true
			var cell: Vector2i = g.local_to_map(g.to_local(a.global_position))
			var touches := false
			for side in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				touches = touches or g.get_cell_source_id(cell + side) == 1
			ok_edge = ok_edge and touches and g.get_cell_source_id(cell) == 0
			ok_reachable = ok_reachable and cell.x < 40
			ok_player = ok_player and a.global_position.distance_to(player.global_position) >= 224.0
			for light: Node2D in get_nodes_in_group("lantern_light"):
				ok_light = ok_light and a.global_position.distance_to(light.global_position) >= 96.0
			for b: Node2D in list:
				if a != b:
					ok_spacing = ok_spacing and a.global_position.distance_to(b.global_position) >= 96.0
		gs.end_day()
		await process_frame
	check("on clean land beside the curse", ok_edge)
	check("never in a cut-off clearing", ok_reachable)
	check("never close to the player", ok_player)
	check("never in lantern light", ok_light)
	check("spread out", ok_spacing)
	check("different places on different days", seen_spots.size() > 6)

	# The old ones are gone by morning, with no build-up.
	var old: Array = alive(spawner)
	gs.end_day()
	await process_frame
	check("old ones vanish", old.all(func(c: Variant) -> bool: return not is_instance_valid(c)))
	var total := 0
	for n in main.get_node("World").get_children():
		if n.scene_file_path.ends_with("creature.tscn"):
			total += 1
	check("no build-up in the world", total == 2)

	# A defeated one comes back the next morning, not sooner.
	var victim: Node = alive(spawner)[0]
	victim.take_hit(9, Vector2.RIGHT)
	await process_frame
	gs.end_day()
	await process_frame
	check("two again next morning", alive(spawner).size() == 2)

	# More healing, more creatures, up to the limit.
	gs.healed_percent = 12.0
	check("2 extra at 12%", spawner.count_for_today() == 4)
	gs.healed_percent = 90.0
	check("capped at the limit", spawner.count_for_today() == 6)
	gs.end_day()
	await process_frame
	check("the cap really spawns", alive(spawner).size() == 6)
	gs.healed_percent = 0.0

	# Lanterns push them away: light up a good part of the edge.
	var spots: Array = spawner.spawn_cells()
	var before: int = spots.size()
	gs.buildings[&"lantern_post"] = 1
	farm.builder.place(spots[0], gs.BUILDINGS[0])
	await physics_frame
	check("a new lantern removes nearby spots", spawner.spawn_cells().size() < before)

	# Healed land opens new places.
	gs.holy_water = 1
	farm.healing.cleanse(Vector2i(36, 13))
	# Tile collision only updates on the next physics frame.
	await physics_frame
	await physics_frame
	var cells: Array = spawner.spawn_cells()
	var on_healed: Array = farm.healing.cleansed.filter(func(c: Vector2i) -> bool: return cells.has(c))
	check("healed land becomes the new edge", not on_healed.is_empty())

	# A saved game starts its morning with creatures too.
	gs.day = 9
	gs.save_game()
	main.free()
	var again: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(again)
	await process_frame
	await process_frame
	var spawner2: Node = again.get_node("Farm").spawner
	check("creatures on load", alive(spawner2).size() >= 2)
	check("ready to move", alive(spawner2)[0].sprite.texture != null)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
