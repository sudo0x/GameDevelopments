extends SceneTree
## Placed lanterns heal the nearest cursed tile each night.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var saves: Node = root.get_node("SaveGame")
	inv.buildings[&"lantern_post"] = 5
	# This test is about lanterns alone: the curse taking land back would change its counts.
	load("res://data/balance.tres").curse_return_per_night = 0
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var hud: Node = main.get_node("HUD")
	var lantern = inv.BUILDINGS[0]
	var healing: Node = farm.healing
	# All messages, because only the newest one stays on screen.
	var notices: Array = []
	gs.notice.connect(func(text: String) -> void: notices.append(text))
	check("lantern has a range", lantern.heal_radius == 4)

	# Far from any curse: nothing happens, and nothing is said.
	farm.builder.place(Vector2i(20, 13), lantern)
	progress.end_day()
	check("no curse in range, nothing healed", healing.cleansed.is_empty())
	check("no message", notices.is_empty())

	# Beside the curse: one tile a night, nearest first.
	var edge := Vector2i(34, 13)
	check("lantern tile is clean", g.get_cell_source_id(edge) == 0)
	farm.builder.place(edge, lantern)
	progress.end_day()
	check("one tile healed", healing.cleansed.size() == 1)
	var first: Vector2i = healing.cleansed[0]
	print("first healed ", first)
	check("it was close", Vector2(first - edge).length() <= 2.0)
	check("the land really healed", g.get_cell_source_id(first) == 0)
	check("message", notices.has("Your lanterns healed 1 tile overnight."))
	check("progress counts it", progress.healed_percent > 0.0)
	progress.end_day()
	check("another the next night", healing.cleansed.size() == 2)
	check("distance never gets shorter", Vector2(healing.cleansed[1] - edge).length() >= Vector2(first - edge).length())

	# Two lanterns, two tiles, never the same one.
	farm.builder.place(Vector2i(34, 15), lantern)
	var before: int = healing.cleansed.size()
	progress.end_day()
	check("two lanterns heal two tiles", healing.cleansed.size() == before + 2)
	check("plural message", notices.has("Your lanterns healed 2 tiles overnight."))
	var unique := {}
	for c: Vector2i in healing.cleansed:
		unique[c] = true
	check("no tile healed twice", unique.size() == healing.cleansed.size())

	# The map's own lanterns don't count, and picking one up stops it.
	farm.builder.pick_up(edge)
	farm.builder.pick_up(Vector2i(34, 15))
	await process_frame
	before = healing.cleansed.size()
	progress.end_day()
	check("no placed lanterns near curse, no healing", healing.cleansed.size() == before)

	# It stops at its range.
	var limit := Vector2i(34, 9)
	farm.builder.place(limit, lantern)
	var nights := 0
	while nights < 80:
		before = healing.cleansed.size()
		progress.end_day()
		nights += 1
		if healing.cleansed.size() == before:
			break
	var far := true
	for c: Vector2i in healing.cleansed:
		if Vector2(c - limit).length() > 4.0 and Vector2(c - edge).length() > 4.0 and Vector2(c - Vector2i(34, 15)).length() > 4.0:
			far = false
	check("never heals beyond its range", far)
	check("runs out of curse to heal", nights < 80)
	check("the outer ring is safe", g.get_cell_source_id(Vector2i(75, 13)) == 1)

	# Saved with the morning.
	check("in the save", saves.farm_state["cleansed"].size() == healing.cleansed.size())
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
