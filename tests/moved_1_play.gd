extends SceneTree
## Moves the shipping box, keeps a map lantern in the bag, then sleeps. Checked by moved_2_check.gd.


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var builder: Node = main.get_node("Farm").builder
	for cell: Vector2i in builder.placed.keys():
		if builder.placed[cell]["starting"] in [&"ShippingBox", &"LanternDoor"]:
			builder.pick_up(cell)
	builder.place(Vector2i(20, 15), inv.building_by_id(&"shipping_box"))
	# Two fences in a vertical line, which must come back with the vertical art.
	var fence: Resource = inv.building_by_id(&"fence")
	inv.add_building(fence, 2)
	builder.place(Vector2i(24, 15), fence)
	builder.place(Vector2i(24, 16), fence)
	await process_frame
	progress.end_day()
	quit()
