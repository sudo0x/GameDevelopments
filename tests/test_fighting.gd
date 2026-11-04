extends SceneTree
## Hitting creatures with the sword, and creatures hurting the player.
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
	gs.has_sword = true
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var player: Node2D = main.get_node("World/Player")
	main.get_node("World/Shade").queue_free()
	var open := Vector2(600, 500)
	player.global_position = open
	player.facing = 3
	await press("tool_7")

	# Two hits, by key.
	var shade := spawn(main, open + Vector2(34, 8))
	await wait(2)
	check("full health", shade.health == 2)
	var beaten: Array = []
	shade.defeated.connect(func(c: Node) -> void: beaten.append(c))
	var x0: float = shade.global_position.x
	await press("use_tool")
	await wait(12)
	check("first hit lands", shade.health == 1)
	check("knocked back", shade.global_position.x > x0 + 8.0)
	check("it chases after being hit", shade.state == 1)
	check("still here", is_instance_valid(shade) and beaten.is_empty())
	check("no damage to the player yet", gs.hearts == 5)
	shade.global_position = open + Vector2(34, 8)
	await wait(14)
	shade.global_position = open + Vector2(34, 8)
	await wait(1)
	await press("use_tool")
	await wait(12)
	check("defeated", shade.health <= 0 and beaten.size() == 1)
	var hits_before: int = shade.health
	shade.take_hit(1, Vector2.RIGHT)
	check("can't be hit again", beaten.size() == 1 and shade.health == hits_before)
	await wait(30)
	check("fades away", not is_instance_valid(shade))
	check("harmless while fading", gs.hearts == 5)

	# Touching hurts, once a second.
	var attacker := spawn(main, open + Vector2(14, 0))
	await wait(4)
	check("contact takes a heart", gs.hearts == 4)
	await wait(12)
	check("the player is knocked back", player.global_position.distance_to(open) > 8.0)
	attacker.global_position = player.global_position + Vector2(10, 0)
	await wait(20)
	check("safe for a moment", gs.hearts == 4)
	var blinked := false
	for i in 12:
		await physics_frame
		blinked = blinked or player.sprite.modulate.a < 1.0
	check("blinks while safe", blinked or gs.hearts < 4)
	attacker.global_position = player.global_position + Vector2(10, 0)
	await wait(50)
	check("hurt again afterwards", gs.hearts <= 3)
	check("visible again", player._safe_left > 0.0 or player.sprite.modulate.a == 1.0)

	# Menus pause the danger.
	var hearts: int = gs.hearts
	player._safe_left = 0.0
	paused = true
	attacker.global_position = player.global_position
	await process_frame
	await process_frame
	check("no damage while paused", gs.hearts == hearts)
	paused = false

	# Fainting to a creature.
	gs.money = 100
	gs.hearts = 1
	var day0: int = gs.day
	player._safe_left = 0.0
	attacker.global_position = player.global_position + Vector2(8, 0)
	await wait(4)
	check("hearts run out", gs.hearts == 0)
	check("day is changing", gs.day_changing)
	check("money lost", gs.money == 90)
	await wait(130)
	check("woke the next day", gs.day == day0 + 1)
	check("the creature stayed behind", attacker.global_position.distance_to(player.global_position) > 150.0)
	check("full hearts", gs.hearts == 5)
	check("day change finished", not gs.day_changing)

	# Nothing can hurt during the fade to sleep.
	attacker.queue_free()
	await wait(2)
	gs.request_sleep()
	await wait(4)
	check("fading", gs.day_changing)
	player._safe_left = 0.0
	player.hurt(5, Vector2.LEFT)
	check("can't be hurt while falling asleep", gs.hearts == 5 and gs.money == 90)
	await wait(130)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
