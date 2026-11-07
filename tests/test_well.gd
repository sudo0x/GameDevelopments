extends SceneTree
## The well waters nearby soil each morning, so crops there grow without watering by hand.
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
	var saves: Node = root.get_node("SaveGame")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var well = inv.building_by_id(&"well")
	check("well exists", well != null and well.water_radius == 2)

	inv.add_material(inv.MATERIALS[0], 5)
	inv.add_material(inv.MATERIALS[1], 8)
	check("craftable", inv.craft(inv.RECIPES[4]) and inv.building_count(well) == 1)
	check("recipe spent", inv.material_count(inv.MATERIALS[0]) == 0 and inv.material_count(inv.MATERIALS[1]) == 0)

	var center := Vector2i(18, 13)
	var near := center + Vector2i(1, 0)
	var edge := center + Vector2i(2, 2)
	var outside := center + Vector2i(3, 0)
	for cell in [near, edge, outside]:
		farm.till(cell)
	farm.plant(near, inv.CROPS[0])
	farm.builder.place(center, well)
	await physics_frame
	check("no water until morning", not farm.is_watered(near))
	check("solid", not farm.can_use(0, center))

	progress.end_day()
	check("waters beside it", farm.is_watered(near))
	check("reaches the corner of the 5x5", farm.is_watered(edge))
	check("stops at its range", not farm.is_watered(outside) and farm.is_tilled(outside))
	check("grass isn't turned to soil", not farm.is_tilled(center + Vector2i(0, 1)))
	check("that first night didn't grow it", farm.crops[near].days_grown == 0)

	progress.end_day()
	progress.end_day()
	progress.end_day()
	check("grows with no watering by hand", farm.crops[near].is_ripe())
	check("still wet each morning", farm.is_watered(near))

	# Watered soil isn't saved, so loading must water it again.
	saves.save_game()
	main.free()
	saves.load_game()
	var again: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(again)
	await process_frame
	var farm2: Node = again.get_node("Farm")
	check("well back after loading", farm2.builder.placed.has(center))
	check("soil wet after loading", farm2.is_watered(near))
	check("outside still dry", not farm2.is_watered(outside))

	# Picking it up stops the watering.
	farm2.builder.pick_up(center)
	await process_frame
	check("well back in the bag", inv.building_count(well) == 1)
	progress.end_day()
	check("dry the next morning", not farm2.is_watered(near))
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
