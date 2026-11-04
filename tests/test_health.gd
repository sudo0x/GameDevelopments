extends SceneTree
## Hearts, taking damage, and fainting.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait_for_fade() -> void:
	for i in 130:
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
	var hud: Node = main.get_node("HUD")
	var player: Node = main.get_node("World/Player")
	var home: Vector2 = player.global_position
	check("starts full", gs.hearts == 5)

	gs.take_damage(2)
	check("damage", gs.hearts == 3 and gs.day == 1)
	gs.end_day()
	check("sleep refills", gs.hearts == 5 and gs.day == 2)

	# Fainting.
	gs.money = 105
	player.global_position = Vector2(1000, 500)
	var seen: Array = []
	gs.fainted.connect(func(lost: int) -> void: seen.append(lost))
	gs.take_damage(9)
	check("never below zero", gs.hearts == 0)
	check("fainted once with the right loss", seen == [10])
	check("money lost", gs.money == 95)
	gs.take_damage(1)
	check("can't faint twice", seen.size() == 1 and gs.money == 95)
	await wait_for_fade()
	check("next day", gs.day == 3)
	check("hearts back", gs.hearts == 5)
	check("woke at home", player.global_position.distance_to(home) < 1.0)
	check("message", hud.notice_label.text == "You fainted and woke up at home. You lost 10 money.")
	check("screen visible again", main.get_node("HUD/Fade").color.a == 0.0)

	# It's saved like any other morning.
	gs.money = 0
	gs.load_game()
	check("loss is saved", gs.money == 95 and gs.day == 3)
	check("full hearts after loading", gs.hearts == 5)

	# Poor players still faint safely.
	gs.money = 5
	gs.take_damage(5)
	await wait_for_fade()
	check("nothing to lose", gs.money == 5 and gs.day == 4)
	check("zero message", hud.notice_label.text.contains("You lost 0 money"))

	# Sleeping normally still works after the change.
	gs.request_sleep()
	await wait_for_fade()
	check("sleeping still works", gs.day == 5)
	check("no faint message from sleeping", gs.money == 5)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
