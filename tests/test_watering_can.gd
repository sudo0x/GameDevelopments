extends SceneTree
## The can holds a limited amount. Wells refill it, and it's full each morning.
const RIGHT := 3
const WATER := 4
const INTERACT := 2

var fails := 0
var farm: Node
var player: Node2D


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await process_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	Input.flush_buffered_events()
	await process_frame


func stand(cell: Vector2i) -> void:
	var g: TileMapLayer = farm.ground
	player.global_position = g.to_global(g.map_to_local(cell)) + Vector2(0, 4)
	player.facing = RIGHT
	await wait(3)


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var gs: Node = root.get_node("GameState")
	var progress: Node = root.get_node("Progress")
	var saves: Node = root.get_node("SaveGame")
	var capacity: int = gs.BALANCE.can_capacity
	var tilled_on_well := Vector2i(25, 8)

	# An older save may have soil or a crop where the starting well now stands.
	saves.farm_state = {
		"tilled": [tilled_on_well, Vector2i(24, 14)],
		"crops": [{"cell": tilled_on_well, "id": &"radish", "days": 1, "blighted": false}],
	}
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	farm = main.get_node("Farm")
	player = main.get_node("World/Player")
	player._safe_left = 999.0
	var hud: Node = main.get_node("HUD")
	var well: Node2D = main.get_node("World/StartingWell")
	var well_area: Node2D = well.get_node("Interact")
	check("the old crop under the well is gone", not farm.crops.has(tilled_on_well) and not farm.is_tilled(tilled_on_well))
	check("other soil is kept", farm.is_tilled(Vector2i(24, 14)))
	check("the starting well is near the house", well.global_position.distance_to(main.get_node("World/House").global_position) < 160.0)
	check("it stands on land", farm.ground.get_cell_source_id(tilled_on_well) == 0)

	# Each water costs one.
	check("the can starts full", inv.can_water == capacity)
	check("a full can isn't shown", not hud.status_text.contains("Water:"))
	var cell := Vector2i(23, 16)
	farm.till(cell)
	farm.plant(cell, inv.CROPS[0])
	await stand(cell + Vector2i.LEFT)
	await press("action")
	check("watering uses the can", farm.is_watered(cell) and inv.can_water == capacity - 1)
	check("the corner shows what's left", hud.status_text.contains("Water: %d of %d" % [capacity - 1, capacity]))

	var water_row: Node = hud.status_rows.get_node("water")
	check("the row shows a picture and a number", water_row.visible and water_row.get_node("Icon").texture != null and water_row.get_node("Value").text == "%d/%d" % [capacity - 1, capacity])
	check("healing shows a number, not words", hud.status_rows.get_node("healed/Value").text == "0.0%")

	# Empty.
	var notices: Array[String] = []
	gs.notice.connect(func(text: String) -> void: notices.append(text))
	inv.can_water = 1
	var second := Vector2i(23, 18)
	farm.till(second)
	farm.plant(second, inv.CROPS[0])
	await stand(second + Vector2i.LEFT)
	await press("action")
	check("the last water works", farm.is_watered(second) and inv.can_water == 0)
	check("it says it's empty", notices.any(func(n: String) -> bool: return n.contains("empty")))
	var third := Vector2i(23, 20)
	farm.till(third)
	farm.plant(third, inv.CROPS[0])
	await stand(third + Vector2i.LEFT)
	check("an empty can can't water", not farm.can_use(1, third))
	check("Action has nothing to do", farm.smart_action(third) == 0)
	await press("action")
	check("no water happens", not farm.is_watered(third) and inv.can_water == 0)
	check("the crop says where to go", farm.crop_status(third).contains("well"))
	check("the Tool can't water either", not farm.can_use(1, third))

	# Refilling.
	await wait(40)
	player.global_position = well_area.global_position + Vector2(0, 5)
	player.facing = 1
	await wait(3)
	check("an empty can makes the well usable", farm.smart_action(Vector2i(24, 14)) == INTERACT)
	await press("action")
	check("the well fills the can", inv.can_water == capacity)
	check("the row hides again", not hud.status_rows.get_node("water").visible)
	check("and the corner goes quiet", not hud.status_text.contains("Water:"))
	await wait(3)
	check("a full can leaves the well alone", farm.smart_action(Vector2i(24, 14)) != INTERACT)

	# A built well refills too.
	var built: BuildingData = inv.building_by_id(&"well")
	inv.add_building(built)
	farm.builder.place(Vector2i(32, 15), built)
	await wait(3)
	inv.can_water = 3
	var node: Node2D = farm.builder.placed[Vector2i(32, 15)]["node"]
	node.get_node("Interact").interact(player)
	check("a built well refills the can", inv.can_water == capacity)

	# Mornings and new games.
	inv.can_water = 2
	progress.end_day()
	check("full each morning", inv.can_water == capacity)
	inv.can_water = 2
	saves.discard_unsaved()
	check("loading fills it", inv.can_water == capacity)

	print("ALL PASS" if fails == 0 else "%d FAILED" % fails)
	quit(fails)
