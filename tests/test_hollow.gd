extends SceneTree
## The hollow: tougher, slower and heavier, and only found far to the east.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func spawn(main: Node, path: String, at: Vector2) -> Node2D:
	var creature: Node2D = load("res://scenes/creatures/creature.tscn").instantiate()
	creature.data = load(path)
	creature.position = at
	main.get_node("World").add_child(creature)
	return creature


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var player: Node2D = main.get_node("World/Player")
	var spawner: Node = farm.spawner
	var shard: Variant = inv.MATERIALS[2]
	var HOLLOW := "res://data/creatures/hollow.tres"
	var SHADE := "res://data/creatures/shade.tres"
	var open := Vector2(600, 500)

	# Which creature goes where.
	check("shades on the shore", spawner.creature_for(Vector2i(30, 13)).id == &"shade")
	check("shades just before the line", spawner.creature_for(Vector2i(51, 13)).id == &"shade")
	check("hollows from the line", spawner.creature_for(Vector2i(52, 13)).id == &"hollow")
	check("hollows in the far east", spawner.creature_for(Vector2i(70, 13)).id == &"hollow")

	# Tougher: 4 hits, and it pays 3 shards.
	var hollow := spawn(main, HOLLOW, open)
	await wait(2)
	check("art", hollow.sprite.texture.get_height() == 72)
	check("bigger body", hollow.get_node("Shape").shape.radius == 14.0)
	var shade := spawn(main, SHADE, open + Vector2(200, 0))
	await wait(2)
	check("a shade's body is its own", shade.get_node("Shape").shape.radius == 8.0)
	shade.queue_free()
	for i in 3:
		hollow.take_hit(1, Vector2.RIGHT)
	check("3 hits isn't enough", hollow.health == 1 and inv.material_count(shard) == 0)
	hollow.take_hit(1, Vector2.RIGHT)
	check("4 defeats it", hollow.health == 0)
	check("3 shards", inv.material_count(shard) == 3)
	check("notice", main.get_node("HUD").notice_label.text == "+3 Curse shard")

	# Heavy: it doesn't float, and a hit moves it less than a shade.
	var heavy := spawn(main, HOLLOW, open + Vector2(0, 60))
	var light := spawn(main, SHADE, open + Vector2(0, -60))
	player.global_position = open + Vector2(400, 0)
	await wait(2)
	var heavy_x: float = heavy.global_position.x
	var light_x: float = light.global_position.x
	heavy.take_hit(1, Vector2.RIGHT)
	light.take_hit(1, Vector2.RIGHT)
	await wait(14)
	var heavy_moved: float = heavy.global_position.x - heavy_x
	var light_moved: float = light.global_position.x - light_x
	print("knockback hollow %.1f, shade %.1f" % [heavy_moved, light_moved])
	check("harder to push", heavy_moved < light_moved / 2.0)
	check("it doesn't float", heavy.sprite.position.y == 0.0)
	light.queue_free()
	heavy.queue_free()
	await wait(2)

	# Slower than the player, and it hits harder.
	var chaser := spawn(main, HOLLOW, open + Vector2(100, 0))
	player.global_position = open
	await wait(2)
	check("sees the player", chaser.state == 1)
	var start: float = chaser.global_position.x
	await wait(60)
	var speed: float = start - chaser.global_position.x
	print("hollow moved %.1f in a second" % speed)
	check("slower than a shade", speed > 25.0 and speed < 45.0)
	await wait(50)
	check("takes 2 hearts", progress.hearts == 3)
	chaser.queue_free()
	await wait(2)

	# Lantern light stops it too.
	var light_node: Node2D = main.get_node("World/LanternSouthEast/Light")
	player._safe_left = 9999.0
	player.global_position = light_node.global_position
	var stopped := spawn(main, HOLLOW, light_node.global_position + Vector2(110, 0))
	var nearest := 9999.0
	for i in 200:
		await physics_frame
		nearest = minf(nearest, stopped.global_position.distance_to(light_node.global_position))
	check("stops at the light", nearest >= 94.0)
	stopped.queue_free()
	await wait(2)

	# They really appear, once healing opens the way east.
	for x in range(35, 60):
		for y in range(11, 16):
			if farm.healing.is_cleansable(Vector2i(x, y)):
				farm.healing._heal(Vector2i(x, y))
	await wait(3)
	player.global_position = Vector2(784, 348)
	await wait(3)
	progress.day = 20
	progress.healed_percent = 90.0
	var saw_hollow := false
	var saw_shade := false
	var rule_ok := true
	for morning in 12:
		progress.end_day()
		progress.healed_percent = 90.0
		await process_frame
		for c: Node2D in spawner.creatures:
			if not is_instance_valid(c):
				continue
			var cell: Vector2i = g.local_to_map(g.to_local(c.global_position))
			saw_hollow = saw_hollow or c.data.id == &"hollow"
			saw_shade = saw_shade or c.data.id == &"shade"
			rule_ok = rule_ok and (c.data.id == &"hollow") == (cell.x >= 52)
	check("hollows appear", saw_hollow)
	check("shades still appear", saw_shade)
	check("each one in its own area", rule_ok)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
