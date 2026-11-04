extends SceneTree
## A fresh start must keep the map's objects where moved_1_play.gd left them.
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
	await process_frame
	var builder: Node = main.get_node("Farm").builder
	var boxes := main.get_node("World").get_children().filter(func(n: Node) -> bool: return n.scene_file_path == "res://scenes/farm/shipping_box.tscn")
	check("one box, not at the old spot", boxes.size() == 1 and boxes[0].position != Vector2(848, 368))
	check("picked-up lantern is gone", not main.has_node("World/LanternDoor"))
	check("the rest stay", main.has_node("World/Workbench") and main.has_node("World/LanternStall"))
	check("4 left where the map put them", builder.starting_left().size() == 4)
	var moved: Dictionary = builder.placed.get(Vector2i(20, 15), {})
	check("box at its new spot", not moved.is_empty() and moved["data"].id == &"shipping_box")
	var fences: Array = [builder.placed.get(Vector2i(24, 15), {}), builder.placed.get(Vector2i(24, 16), {})]
	check("a vertical fence line loads vertical", fences.all(func(e: Dictionary) -> bool: return not e.is_empty() and e["node"].vertical and e["node"].get_node("Sprite2D").texture == e["node"].VERTICAL_TEXTURE))
	check("lantern still in the bag", gs.building_count(gs.building_by_id(&"old_lantern_post")) == 1)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
