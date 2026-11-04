extends SceneTree
var fails := 0
func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1
func _initialize() -> void:
	_run()
func _run() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var player: Node = main.get_node("World/Player")
	var farm: Node = main.get_node("Farm")
	var mood: CanvasModulate = main.get_node("Mood")
	check("mood darkens but not black", mood.color.v > 0.6 and mood.color.v < 1.0)
	var count := 0
	for n in main.get_node("World").get_children():
		if n.name.begins_with("Lantern"):
			count += 1
			var light: PointLight2D = n.get_node("Light")
			check(n.name + " light on", light.enabled and light.texture != null)
			var cell: Vector2i = farm.ground.local_to_map(farm.ground.to_local(n.global_position))
			check(n.name + " on grass", farm.ground.get_cell_source_id(cell) == 0)
			player.global_position = n.global_position + Vector2(0, 16)
			for i in 3:
				await physics_frame
			Input.action_press("move_up")
			for i in 40:
				await physics_frame
			Input.action_release("move_up")
			check(n.name + " blocks walking", player.global_position.y > n.global_position.y - 4)
	check("four lanterns", count == 4)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
