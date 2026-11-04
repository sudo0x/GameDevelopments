extends SceneTree
## Creatures can't enter lantern light, so lit land is safe.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func spawn(main: Node, at: Vector2) -> Node2D:
	var shade: Node2D = load("res://scenes/creatures/creature.tscn").instantiate()
	shade.data = load("res://data/creatures/shade.tres")
	shade.position = at
	main.get_node("World").add_child(shade)
	return shade


## The closest the shade gets to a point over some frames.
func closest(shade: Node2D, to: Vector2, frames: int) -> float:
	var best := 99999.0
	for i in frames:
		await physics_frame
		best = minf(best, shade.global_position.distance_to(to))
	return best


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var farm: Node = main.get_node("Farm")
	var player: Node2D = main.get_node("World/Player")
	var radius: float = gs.BALANCE.lantern_safe_radius
	check("the 4 map lanterns count", get_nodes_in_group("lantern_light").size() == 4)

	# A map lantern: stand under it, and the shade can't reach.
	var light: Node2D = main.get_node("World/LanternSouthEast/Light")
	player.global_position = light.global_position
	var shade := spawn(main, light.global_position + Vector2(106, 0))
	await wait(2)
	check("it sees the player", shade.state == 1)
	var nearest: float = await closest(shade, light.global_position, 240)
	print("nearest to the light %.1f of %.1f" % [nearest, radius])
	check("stops at the light's edge", nearest >= radius - 2.0)
	check("it does come right up to the edge", nearest < radius + 10.0)
	check("no damage in the light", gs.hearts == 5)
	check("still hunting", shade.state == 1)

	# The player on the far side: it goes around, and never through.
	player.global_position = light.global_position + Vector2(0, -110)
	nearest = await closest(shade, light.global_position, 300)
	check("going round, never through", nearest >= radius - 2.0)
	check("got round the light to the player", shade.global_position.distance_to(player.global_position) < 60.0)
	player._safe_left = 9999.0

	# Knocked into the light, it leaves.
	shade.global_position = light.global_position + Vector2(40, 0)
	await wait(80)
	check("leaves after being pushed in", shade.global_position.distance_to(light.global_position) >= radius - 4.0)

	# A lantern the player placed works the same, and picking it up ends the safety.
	var cell := Vector2i(16, 12)
	gs.buildings[&"lantern_post"] = 1
	farm.builder.place(cell, gs.BUILDINGS[0])
	await wait(2)
	var placed: Node2D = farm.builder.placed[cell]["node"].get_node("Light")
	player.global_position = placed.global_position
	shade.global_position = placed.global_position + Vector2(-100, 30)
	nearest = await closest(shade, placed.global_position, 240)
	check("placed lanterns count", nearest >= radius - 2.0)
	farm.builder.pick_up(cell)
	await process_frame
	nearest = await closest(shade, player.global_position, 150)
	check("no lantern, no safety", nearest < 40.0)

	# A lantern placed right beside a creature drives it out.
	var at: Vector2 = shade.global_position
	var near_cell: Vector2i = farm.ground.local_to_map(farm.ground.to_local(at))
	gs.buildings[&"lantern_post"] = 1
	farm.builder.place(near_cell, gs.BUILDINGS[0])
	await wait(2)
	var new_light: Node2D = farm.builder.placed[near_cell]["node"].get_node("Light")
	player.global_position = Vector2(600, 400)
	await wait(130)
	check("driven out by a new lantern", shade.global_position.distance_to(new_light.global_position) >= radius - 4.0)
	farm.builder.pick_up(near_cell)
	await process_frame

	# Wandering never drifts in, and it doesn't get stuck on the edge.
	shade.queue_free()
	await process_frame
	player.global_position = Vector2(1100, 250)
	var wanderer := spawn(main, light.global_position + Vector2(radius + 12, 0))
	await wait(2)
	var start: Vector2 = wanderer.global_position
	var moved := 0.0
	nearest = 99999.0
	for i in 900:
		await physics_frame
		nearest = minf(nearest, wanderer.global_position.distance_to(light.global_position))
		moved = maxf(moved, wanderer.global_position.distance_to(start))
	check("wandering stays out", nearest >= radius - 2.0)
	check("wandering isn't stuck", moved > 10.0)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
