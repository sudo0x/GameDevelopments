extends SceneTree
## The map's shipping box, workbench and lantern posts can be picked up and placed again.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await physics_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	Input.flush_buffered_events()
	await physics_frame


## Where the builder keeps one of the map's own objects.
func cell_of(builder: Node, node_name: String) -> Vector2i:
	for cell: Vector2i in builder.placed:
		if builder.placed[cell].get("starting", &"") == node_name:
			return cell
	return Vector2i(-1, -1)


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
	var player: Node = main.get_node("World/Player")
	var hud: Node = main.get_node("HUD")
	var builder: Node = farm.builder
	var left: Array = builder.starting_left()
	check("6 movable objects", left.size() == 6)
	for name in ["ShippingBox", "Workbench", "LanternDoor", "LanternStall", "LanternSouthWest", "LanternSouthEast"]:
		check(name + " is movable", left.has(name))
	check("house and stall aren't", not left.has("House") and not left.has("ShopStall"))
	check("the box is right under it", farm.ground.local_to_map(farm.ground.to_local(main.get_node("World/ShippingBox").global_position)) == cell_of(builder, "ShippingBox"))
	var map_lantern: Dictionary = builder.placed[cell_of(builder, "LanternDoor")]
	check("the map's lanterns are old ones that don't heal", map_lantern["data"].id == &"old_lantern_post" and map_lantern["data"].heal_radius == 0)

	# The Hand tool picks up the shipping box.
	var box_cell := cell_of(builder, "ShippingBox")
	player.global_position = farm.ground.to_global(farm.ground.map_to_local(box_cell + Vector2i(0, 1)))
	player.facing = 1  # Player.Facing.UP
	await press("tool_4")
	await physics_frame
	await physics_frame
	check("facing the box " + str(farm.target_cell), farm.target_cell == box_cell)
	check("says it can be picked up", hud.crop_status_label.text == "Shipping box: press 4, then Space to pick up.")
	await press("use_tool")
	await process_frame
	var box_data: Resource = inv.building_by_id(&"shipping_box")
	check("box in the bag", inv.building_count(box_data) == 1 and not builder.placed.has(box_cell))
	check("box gone from the map", not main.has_node("World/ShippingBox"))
	check("no longer a starting object", not builder.starting_left().has("ShippingBox"))

	# The Build tool offers it only while one is in the bag.
	await press("tool_6")
	var offered := []
	for i in inv.BUILDINGS.size():
		offered.append(player.selected_building().id)
		await press("seed_next")
	check("build tool offers the box", offered.has(&"shipping_box"))
	check("but not the workbench, with none in the bag", not offered.has(&"workbench"))

	# Placed somewhere else, it still works.
	var new_cell := Vector2i(20, 15)
	check("can build there", farm.can_build(new_cell))
	builder.place(new_cell, box_data)
	var box: Node = builder.placed[new_cell]["node"]
	check("placed", inv.building_count(box_data) == 0 and box.scene_file_path == "res://scenes/farm/shipping_box.tscn")
	inv.add_harvest(inv.CROPS[0])
	box.get_node("Interact").interact(player)
	check("still ships", inv.harvest_count(inv.CROPS[0]) == 0 and not inv.shipped.is_empty())

	# A map lantern picked up is an old lantern: it keeps its light, but doesn't heal.
	builder.pick_up(cell_of(builder, "LanternSouthWest"))
	var old: Resource = inv.building_by_id(&"old_lantern_post")
	check("old lantern in the bag", inv.building_count(old) == 1)

	progress.end_day()
	var state: Dictionary = saves.farm_state
	check("saved what's left", state["starting_objects"].size() == 4)
	check("saved the moved box", state["buildings"].has({"cell": new_cell, "id": &"shipping_box"}))
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
