extends SceneTree
## Land the curse took back stays cursed after a restart, and its find doesn't come back.
const GRASS := 0
const CURSED := 1
var fails := 0
func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1
func _initialize() -> void:
	_run()
func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var healing: Node = farm.healing
	var find := Vector2i(53, 11)
	# 9 healed, 1 taken by hand, then 3 more that night.
	check("the smaller land came back", healing.cleansed.size() == 5)
	check("kept tiles are clean", healing.cleansed.all(func(c: Vector2i) -> bool: return g.get_cell_source_id(c) == GRASS))
	check("returned land stays cursed", g.get_cell_source_id(find) == CURSED)
	check("the dug find is remembered", healing.dug_finds.has(find) and not healing.finds.has(find))
	check("no glimmer on it", not healing._glimmers.has(find))
	var file := FileAccess.open("user://marked.txt", FileAccess.READ)
	var marked_before: Array = file.get_var()
	file.close()
	check("a restart marks the same tiles", marked_before == Array(healing.marked))
	check("a blighted crop stays blighted", farm.crops[Vector2i(20, 13)].blighted)
	var money: int = inv.money
	inv.holy_water = 1
	healing.cleanse(find)
	check("healing it again pays nothing", g.get_cell_source_id(find) == GRASS and inv.money == money)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
