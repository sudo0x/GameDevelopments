extends SceneTree
## A fresh start must remember what gathered_1_play.gd gathered.
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
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var spots: Dictionary = farm.gathering.spots
	var tree: Node2D = spots[Vector2i(22, 6)]
	var rock: Node2D = spots[Vector2i(18, 7)]
	var hidden: Node2D = spots[Vector2i(44, 12)]
	check("materials kept", inv.material_count(inv.MATERIALS[0]) == 6 and inv.material_count(inv.MATERIALS[1]) == 2)
	check("tree stays a stump", tree.gathered and tree.sprite.texture == tree.data.remains_texture)
	check("countdown kept", tree.days_until_regrow == 4 and rock.days_until_regrow == 6)
	check("rubble stays walkable", rock.shape.disabled)
	check("stump stays solid", not tree.shape.disabled)
	check("revealed one stays gathered and visible", hidden.gathered and hidden.visible)
	check("half-hit tree starts whole", not spots[Vector2i(14, 7)].gathered and spots[Vector2i(14, 7)].hits_left == 3)
	check("others untouched and hidden", not spots[Vector2i(60, 10)].revealed)
	for night in 4:
		progress.end_day()
	check("regrows after reloading", not tree.gathered)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
