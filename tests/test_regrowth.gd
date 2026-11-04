extends SceneTree
## Gathered trees and rocks grow back after a few nights, unless the cell is in use.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func gather(farm: Node, cell: Vector2i) -> void:
	for i in 3:
		farm.gathering.hit(cell)


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var wood = gs.MATERIALS[0]
	var tree_cell := Vector2i(22, 6)
	var rock_cell := Vector2i(18, 7)
	var tree: Node2D = farm.gathering.spots[tree_cell]
	var rock: Node2D = farm.gathering.spots[rock_cell]

	gather(farm, tree_cell)
	gather(farm, rock_cell)
	check("tree waits 5 nights", tree.days_until_regrow == 5)
	check("rock waits 7 nights", rock.days_until_regrow == 7)
	check("status counts down", farm.gathering.status(tree_cell) == "Tree: grows back in 5 days.")
	for night in 4:
		gs.end_day()
	check("not back after 4 nights", tree.gathered and tree.days_until_regrow == 1)
	check("says 1 day", farm.gathering.status(tree_cell) == "Tree: grows back in 1 day.")
	gs.end_day()
	await physics_frame
	await physics_frame
	check("back after 5 nights", not tree.gathered and tree.hits_left == 3)
	check("whole art again", tree.sprite.texture == tree.data.whole_texture)
	check("can gather again", farm.gathering.can_hit(tree_cell))
	gather(farm, tree_cell)
	check("second harvest pays", gs.material_count(wood) == 6)

	# Rubble can be farmed, so a rock must not grow back on top of a crop.
	await physics_frame
	await physics_frame
	farm.till(rock_cell)
	farm.plant(rock_cell, gs.CROPS[0])
	gs.end_day()
	gs.end_day()
	check("rock waits while the cell is farmed", rock.gathered and rock.days_until_regrow == 0)
	check("no status when it's only waiting", farm.gathering.status(rock_cell) == "")
	check("crop unharmed", farm.crops.has(rock_cell))
	farm.soil.erase_cell(rock_cell)
	farm.harvest(rock_cell)
	gs.end_day()
	await physics_frame
	await physics_frame
	check("rock returns once the cell is free", not rock.gathered)
	check("regrown rock is solid again", not rock.shape.disabled)
	check("can't till a regrown rock", not farm.can_use(0, rock_cell))
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
