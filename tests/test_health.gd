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
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var saves: Node = root.get_node("SaveGame")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var hud: Node = main.get_node("HUD")
	var player: Node = main.get_node("World/Player")
	var home: Vector2 = player.global_position
	check("starts full", progress.hearts == 5)

	progress.take_damage(2)
	check("damage", progress.hearts == 3 and progress.day == 1)
	progress.end_day()
	check("sleep refills", progress.hearts == 5 and progress.day == 2)

	# Fainting.
	inv.money = 105
	player.global_position = Vector2(1000, 500)
	var seen: Array = []
	progress.fainted.connect(func(lost: int) -> void: seen.append(lost))
	progress.take_damage(9)
	check("never below zero", progress.hearts == 0)
	check("fainted once with the right loss", seen == [10])
	check("money lost", inv.money == 95)
	progress.take_damage(1)
	check("can't faint twice", seen.size() == 1 and inv.money == 95)
	await wait_for_fade()
	check("next day", progress.day == 3)
	check("hearts back", progress.hearts == 5)
	check("woke at home", player.global_position.distance_to(home) < 1.0)
	check("message", hud.notice_label.text == "You fainted and woke up at home. You lost 10 money.")
	check("screen visible again", main.get_node("HUD/Fade").color.a == 0.0)

	# It's saved like any other morning.
	inv.money = 0
	saves.load_game()
	check("loss is saved", inv.money == 95 and progress.day == 3)
	check("full hearts after loading", progress.hearts == 5)

	# Poor players still faint safely.
	inv.money = 5
	progress.take_damage(5)
	await wait_for_fade()
	check("nothing to lose", inv.money == 5 and progress.day == 4)
	check("zero message", hud.notice_label.text.contains("You lost 0 money"))

	# Sleeping normally still works after the change.
	gs.request_sleep()
	await wait_for_fade()
	check("sleeping still works", progress.day == 5)
	check("no faint message from sleeping", inv.money == 5)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
