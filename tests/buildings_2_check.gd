extends SceneTree
## A fresh start must bring back what buildings_1_play.gd placed.
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
	var g: TileMapLayer = farm.ground
	var cell := Vector2i(16, 12)
	check("placed building back", farm.builder.placed.has(cell) and farm.builder.to_state().size() == 1)
	check("unplaced one kept", inv.building_count(inv.BUILDINGS[0]) == 1)
	var node: Node2D = farm.builder.placed[cell]["node"]
	check("in the same place", node.global_position == g.to_global(g.map_to_local(cell) + farm.BUILDING_BASE))
	check("it's solid", not farm.can_use(0, cell))
	check("light works after loading", node.get_node("Light").enabled)
	progress.end_day()
	check("saved again without duplicates", saves.farm_state["buildings"].size() == 1)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
