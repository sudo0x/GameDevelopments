extends SceneTree
## Healing lanterns and a restored shrine keep the returning curse away from the land around them.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	inv.holy_water = 10
	inv.buildings[&"lantern_post"] = 2
	inv.buildings[&"fence"] = 1
	progress.day = 5
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var healing: Node = farm.healing
	main.get_node("World/Player")._safe_left = 9999.0
	var lantern = inv.BUILDINGS.filter(func(b: Resource) -> bool: return b.id == &"lantern_post")[0]
	var fence = inv.BUILDINGS.filter(func(b: Resource) -> bool: return b.id == &"fence")[0]

	# A lantern guards a square, corners included.
	var at := Vector2i(34, 13)
	var inside := at + Vector2i(2, 0)
	var corner := at + Vector2i(2, 2)
	var outside := at + Vector2i(3, 0)
	check("land starts unprotected", farm._can_curse_take(inside))
	farm.builder.place(at, lantern)
	check("2 tiles from a lantern is safe", not farm._can_curse_take(inside))
	check("so is the corner of its square", not farm._can_curse_take(corner))
	check("3 tiles from a lantern isn't", farm._can_curse_take(outside))

	# A whole night beside a lantern loses nothing.
	healing.cleanse(Vector2i(35, 13))
	var patch: Array = healing.cleansed.duplicate()
	progress.end_day()
	check("nothing lit is marked", healing.marked.is_empty())
	progress.end_day()
	check("a lit patch survives the night", patch.all(func(c: Vector2i) -> bool: return healing.cleansed.has(c)))
	check("the lantern still heals", healing.cleansed.size() > patch.size())

	# Without the lantern, the same land is open to the curse again.
	farm.builder.pick_up(at)
	await process_frame
	check("picking the lantern up ends its protection", farm._can_curse_take(inside))

	# Only healing lanterns count.
	var fence_at := Vector2i(20, 13)
	farm.builder.place(fence_at, fence)
	check("a fence protects nothing nearby", farm._can_curse_take(fence_at + Vector2i(1, 0)))
	var old_lantern: Vector2i = farm.builder.placed.keys().filter(
		func(c: Vector2i) -> bool: return farm.builder.placed[c]["data"].id == &"old_lantern_post")[0]
	check("the map's old lanterns protect nothing", farm._can_curse_take(old_lantern + Vector2i(1, 0)))

	# The shrine, only once restored.
	var shrine: Vector2i = healing._shrine_cell()
	var near := shrine + Vector2i(9, 0)
	var far := shrine + Vector2i(10, 0)
	check("a broken shrine protects nothing", farm._can_curse_take(near))
	healing.shrine.restored = true
	check("9 tiles from a restored shrine is safe", not farm._can_curse_take(near))
	check("10 tiles from it isn't", farm._can_curse_take(far))

	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
