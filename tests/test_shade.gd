extends SceneTree
## The shade wanders near home, chases a close player, gives up, and can't cross the curse.
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


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var player: Node2D = main.get_node("World/Player")
	var shade := spawn(main, Vector2(1072, 528))
	await wait(2)
	var WANDER := 0
	var CHASE := 1
	var home: Vector2 = shade._home
	check("art set", shade.sprite.texture == shade.data.texture)
	check("in the y-sorted World", shade.get_parent().name == "World")
	check("starts wandering", shade.state == WANDER)

	# Wandering stays near home, and really moves.
	var furthest := 0.0
	var low := 99.0
	var high := -99.0
	var flips := {}
	var on_curse := false
	for i in 900:
		await physics_frame
		furthest = maxf(furthest, shade.global_position.distance_to(home))
		low = minf(low, shade.sprite.position.y)
		high = maxf(high, shade.sprite.position.y)
		# The middle of its body: its base sits right on the body's bottom edge.
		on_curse = on_curse or g.get_cell_source_id(g.local_to_map(g.to_local(shade.global_position + Vector2(0, -8)))) == 1
	print("wander furthest %.1f, float %.1f to %.1f" % [furthest, low, high])
	check("it moved", furthest > 8.0)
	check("stays near home", furthest < shade.data.wander_radius + 8.0)
	check("it floats", high - low > 4.0)
	check("still wandering with the player far away", shade.state == WANDER)
	check("never on the curse", not on_curse)

	# Chasing. Fighting has its own test, so the player can't be hurt here.
	player._safe_left = 9999.0
	player.global_position = shade.global_position + Vector2(-90, 0)
	await wait(2)
	check("sees a close player", shade.state == CHASE)
	var start: float = shade.global_position.distance_to(player.global_position)
	await wait(40)
	check("gets closer", shade.global_position.distance_to(player.global_position) < start - 20.0)
	check("faces the player", shade.sprite.flip_h == false)
	await wait(90)
	check("reaches the player", shade.global_position.distance_to(player.global_position) < 30.0)

	# It doesn't block the player, a tile, or a sword swing.
	var at: Vector2 = player.global_position
	Input.action_press("move_left")
	await wait(1)
	Input.action_release("move_left")
	Input.action_press("move_right")
	await wait(30)
	Input.action_release("move_right")
	check("the player walks through it", player.global_position.x > at.x + 30.0)
	var free_cell := Vector2i(32, 15)
	shade.global_position = g.to_global(g.map_to_local(free_cell))
	player.global_position = Vector2(500, 400)
	await wait(2)
	check("doesn't block building", farm.can_build(g.local_to_map(g.to_local(shade.global_position))))
	player.global_position = shade.global_position + Vector2(30, -10)
	await wait(2)
	gs.has_sword = true
	player.sword.swing(Vector2.LEFT)
	await wait(20)
	check("a single hit doesn't defeat it", is_instance_valid(shade) and shade.health >= 1)

	# Giving up.
	player.global_position = Vector2(500, 400)
	await wait(2)
	check("gives up when the player leaves", shade.state == WANDER)

	# It stops at the curse when chasing.
	var east := g.to_global(g.map_to_local(Vector2i(34, 13)))
	shade.global_position = east
	player.global_position = east + Vector2(0, 0)
	await wait(2)
	player.global_position = g.to_global(g.map_to_local(Vector2i(38, 13)))
	await wait(120)
	var shade_cell: Vector2i = g.local_to_map(g.to_local(shade.global_position + Vector2(0, -8)))
	check("can't cross cursed land", g.get_cell_source_id(shade_cell) == 0)

	# The game pauses it.
	var frozen: Vector2 = shade.global_position
	paused = true
	await process_frame
	await process_frame
	await process_frame
	check("stops when paused", shade.global_position == frozen)
	paused = false

	# Not saved.
	gs.end_day()
	check("not in the save", not str(gs.farm_state).contains("shade"))
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
