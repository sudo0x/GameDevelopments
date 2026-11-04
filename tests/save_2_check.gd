extends SceneTree
## Run 2: a fresh process must resume the morning after run 1.
var fails := 0
func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1
func _initialize() -> void:
	_run()
func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var hud: Node = main.get_node("HUD")
	var c := gs.CROPS as Array
	check("day", gs.day == 5)
	check("money paid and kept", gs.money == 200)
	check("seeds", gs.seed_count(c[0]) == 8 and gs.seed_count(c[1]) == 4 and gs.seed_count(c[2]) == 2)
	check("harvest", gs.harvest_count(c[0]) == 2)
	check("after-save pumpkin lost", gs.harvest_count(c[2]) == 0)
	check("shipping empty", gs.shipped.is_empty())
	check("dictionary keys still StringName", typeof(gs.seeds.keys()[0]) == TYPE_STRING_NAME)
	check("tilled empty cell", farm.is_tilled(Vector2i(20, 12)) and not farm.crops.has(Vector2i(20, 12)))
	check("soil dry", not farm.is_watered(Vector2i(20, 12)) and not farm.is_watered(Vector2i(14, 10)))
	check("4 crops back", farm.crops.size() == 4)
	var radish: Node = farm.crops[Vector2i(14, 10)]
	var carrot: Node = farm.crops[Vector2i(15, 10)]
	var pumpkin: Node = farm.crops[Vector2i(16, 10)]
	var dry: Node = farm.crops[Vector2i(17, 10)]
	print("days/stage ", radish.days_grown, "/", radish.stage, " ", carrot.days_grown, "/", carrot.stage, " ", pumpkin.days_grown, "/", pumpkin.stage, " ", dry.days_grown, "/", dry.stage)
	check("radish ripe", radish.is_ripe() and radish.days_grown == 3)
	check("carrot growing", carrot.days_grown == 3 and carrot.stage == 2)
	check("pumpkin growing", pumpkin.days_grown == 3 and pumpkin.stage == 1)
	check("unwatered still seed", dry.days_grown == 0 and dry.stage == 0)
	check("crop sprite shows stage", carrot.sprite.frame == 2 and radish.sprite.frame == 3)
	check("crop in World", radish.get_parent().name == "World")
	check("HUD day", hud.day_label.text == "Day 5")
	check("HUD money", hud.money_label.text == "200")
	farm.harvest(Vector2i(14, 10))
	check("restored crop harvests", gs.harvest_count(c[0]) == 3)
	farm.water(Vector2i(15, 10))
	gs.end_day()
	check("restored crop keeps growing", carrot.days_grown == 4)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
