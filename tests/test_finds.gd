extends SceneTree
var fails := 0
func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1
func glimmers(farm: Node) -> int:
	return farm.healing.get_children().filter(func(n: Node) -> bool: return n.scene_file_path.ends_with("find_glimmer.tscn") and not n.is_queued_for_deletion()).size()
func _initialize() -> void:
	_run()
func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.holy_water = 50
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var hud: Node = main.get_node("HUD")
	check("8 finds", farm.healing.finds.size() == 8)
	var ok := true
	var hits := 0
	for c: Vector2i in farm.healing.finds:
		ok = ok and farm.healing.is_cleansable(c)
		for d: Vector2i in farm.healing.finds:
			if c != d and absi(c.x - d.x) <= 2 and absi(c.y - d.y) <= 2:
				hits += 1
	check("every find is on healable cursed land", ok)
	check("no two finds fit one patch", hits == 0)
	check("8 glimmers", glimmers(farm) == 8)
	var total: int = farm.healing._cursed_total
	print("cursed total ", total)
	check("total sensible", total > 800 and total < 1500)
	check("starts at 0", gs.healed_percent == 0.0)
	check("HUD shows 0.0%", hud.status_label.text.contains("Island healed: 0.0%"))

	var far := Vector2i(40, 3)
	farm.healing.cleanse(far)
	var n: int = farm.healing.cleansed.size()
	check("no find, no reward", gs.money == 0 and hud.notice_label.text == "")
	check("percent moves", is_equal_approx(gs.healed_percent, 100.0 * n / total))
	check("HUD percent", hud.status_label.text.contains("Island healed: %.1f%%" % gs.healed_percent))

	farm.healing.cleanse(Vector2i(38, 10))
	check("money find", gs.money == 40)
	check("notice text", hud.notice_label.text == "You dug up 40 money!")
	check("notice visible", hud.notice_label.modulate.a == 1.0)
	await process_frame
	check("glimmer gone", glimmers(farm) == 7)
	var water: int = gs.holy_water
	farm.healing.cleanse(Vector2i(45, 8))
	check("holy water find (spent 1, found 2)", gs.holy_water == water + 1)
	var seeds0: int = gs.seed_count(gs.CROPS[1])
	farm.healing.cleanse(Vector2i(47, 12))
	check("seed find", gs.seed_count(gs.CROPS[1]) == seeds0 + 3)
	# Notices take turns (test_notices.gd), so this one waits behind the earlier finds.
	check("seed notice waits its turn", hud._waiting_notices.has("You dug up 3 carrot seeds!"))
	# Find at the edge of a patch, not the center.
	var money0: int = gs.money
	farm.healing.cleanse(Vector2i(54, 12))
	check("find at patch corner", gs.money == money0 + 80)
	# Each queued notice gets its turn, then the last fades.
	for i in 600:
		await process_frame
	check("last find shown last", hud.latest_notice() == "You dug up 80 money!" and hud._waiting_notices.is_empty())
	check("notice faded", hud.notice_label.modulate.a < 0.05)

	# Save then reload through a fresh farm.
	gs.end_day()
	var cells: int = farm.healing.cleansed.size()
	var money1: int = gs.money
	main.free()
	var again: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(again)
	await process_frame
	var farm2: Node = again.get_node("Farm")
	check("no reward paid again on load", gs.money == money1)
	check("found finds stay gone", glimmers(farm2) == 4)
	check("percent restored", is_equal_approx(gs.healed_percent, 100.0 * cells / total))
	check("total same after load", farm2.healing._cursed_total == total)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
