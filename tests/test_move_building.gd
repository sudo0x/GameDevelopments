extends SceneTree
## Phones: press and hold a building, drag it, let go. Holds must not start on the joystick or a
## button, and a tap, a slide or a bad spot must leave the building where it was.
const FINGER := 1

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


func touch(at: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = FINGER
	e.position = root.get_final_transform() * at
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func drag(at: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = FINGER
	e.position = root.get_final_transform() * at
	Input.parse_input_event(e)
	Input.flush_buffered_events()


## Where a cell's building shows on screen, a little above its base.
func screen_of(cell: Vector2i) -> Vector2:
	var g: TileMapLayer = farm.ground
	return root.get_canvas_transform() * g.to_global(g.map_to_local(cell))


func hold(at: Vector2) -> void:
	touch(at, true)
	await wait(40)


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var saves: Node = root.get_node("SaveGame")
	var progress: Node = root.get_node("Progress")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	farm = main.get_node("Farm")
	player = main.get_node("World/Player")
	player._safe_left = 999.0
	var controls: Node = main.get_node("HUD/TouchControls")
	var mover: Node = farm.mover
	var g: TileMapLayer = farm.ground
	controls.set_active(true)
	player.global_position = g.to_global(g.map_to_local(Vector2i(22, 12)))
	await wait(30)

	var fence: BuildingData = inv.building_by_id(&"fence")
	var from := Vector2i(24, 12)
	var to := Vector2i(25, 14)
	inv.add_building(fence)
	farm.builder.place(from, fence)
	var bag_count: int = inv.building_count(fence)
	await wait(3)

	# A quick tap does nothing.
	touch(screen_of(from), true)
	await wait(5)
	touch(screen_of(from), false)
	await wait(40)
	check("a tap doesn't lift it", not mover.moving and farm.builder.placed.has(from))

	# Sliding off during the hold cancels it.
	touch(screen_of(from), true)
	await wait(5)
	drag(screen_of(from) + Vector2(30, 0))
	await wait(40)
	check("a slide doesn't lift it", not mover.moving)
	touch(screen_of(from), false)
	await wait(2)

	# Empty ground, and the house, can't be held.
	await hold(screen_of(Vector2i(23, 14)))
	check("empty ground lifts nothing", not mover.moving)
	touch(screen_of(Vector2i(23, 14)), false)
	await wait(2)

	# Holding, dragging and letting go.
	await hold(screen_of(from))
	check("a hold lifts it", mover.moving)
	var node: Node2D = farm.builder.placed[from]["node"]
	check("it looks lifted", node.modulate.a < 1.0)
	check("the preview shows", farm.build_preview.visible)
	drag(screen_of(to))
	await wait(3)
	check("the preview follows the finger", farm.build_preview.position == g.map_to_local(to) + farm.BUILDING_BASE)
	check("it's green on free ground", farm.build_preview.modulate == farm.build_preview.VALID_COLOR)
	touch(screen_of(to), false)
	await wait(3)
	check("letting go moves it", farm.builder.placed.has(to) and not farm.builder.placed.has(from))
	check("the old tile is free", farm.can_build(from))
	check("it never went in the bag", inv.building_count(fence) == bag_count)
	check("the preview hides", not farm.build_preview.visible and not mover.moving)

	# Held by its art, above its own tile.
	var well: BuildingData = inv.building_by_id(&"well")
	inv.add_building(well)
	var tall := Vector2i(27, 12)
	farm.builder.place(tall, well)
	await wait(3)
	await hold(screen_of(tall) + Vector2(0, -8))
	check("a building can be held by its art", mover.moving)
	touch(screen_of(tall) + Vector2(0, -8), false)
	await wait(3)
	check("dropped on itself, it stays", farm.builder.placed.has(tall) and farm.builder.placed[tall]["node"].modulate.a == 1.0)

	# A bad spot leaves it where it was.
	await hold(screen_of(to))
	var blocked: Vector2i = tall
	drag(screen_of(blocked))
	await wait(3)
	check("it's red on a taken tile", farm.build_preview.modulate == farm.build_preview.INVALID_COLOR)
	touch(screen_of(blocked), false)
	await wait(3)
	check("letting go on red leaves it", farm.builder.placed.has(to) and farm.builder.placed[to]["data"] == fence and farm.builder.placed[blocked]["data"] == well)
	check("and it looks normal again", farm.builder.placed[to]["node"].modulate.a == 1.0)

	# A menu or the end of the day ends a hold.
	await hold(screen_of(to))
	main.get_node("HUD/BagMenu").open()
	await wait(3)
	check("a menu ends the drag", not mover.moving and farm.builder.placed[to]["node"].modulate.a == 1.0)
	main.get_node("HUD/BagMenu").close()
	touch(screen_of(to), false)
	await wait(3)
	await hold(screen_of(to))
	progress.day_changing = true
	await wait(3)
	check("the day changing ends the drag", not mover.moving)
	progress.day_changing = false
	touch(screen_of(to), false)
	await wait(3)

	# Buttons and the joystick come first.
	var box: Dictionary = {}
	for cell: Vector2i in farm.builder.placed:
		if farm.builder.placed[cell].has("starting"):
			box = {"cell": cell, "entry": farm.builder.placed[cell]}
			break
	check("the screen's buttons aren't free spots", not controls.is_free_spot(Vector2(596, 296)) and not controls.is_free_spot(Vector2(526, 262)))
	check("the joystick isn't a free spot", not controls.is_free_spot(Vector2(96, 286)))
	check("the middle of the screen is free", controls.is_free_spot(Vector2(320, 120)))
	var thumb := Vector2(96, 286)
	var under: Vector2i = g.local_to_map(g.to_local(root.get_canvas_transform().affine_inverse() * thumb))
	check("there's room under the joystick", farm.can_build(under))
	inv.add_building(fence)
	farm.builder.place(under, fence)
	await wait(3)
	check("a building sits under the thumb", farm.builder.cell_at(root.get_canvas_transform().affine_inverse() * screen_of(under)) == under)
	await hold(screen_of(under))
	check("a hold on the joystick lifts nothing", not mover.moving)
	touch(screen_of(under), false)
	await wait(3)

	# A map object moved this way is saved where it went.
	player.global_position = box["entry"]["node"].global_position + Vector2(-90, 0)
	await wait(30)
	var old: Vector2i = box["cell"]
	var name_before: String = box["entry"]["starting"]
	var target := old + Vector2i(-1, 1)
	var free := false
	for offset: Vector2i in [Vector2i(-1, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0)]:
		if farm.can_build(old + offset):
			target = old + offset
			free = true
			break
	check("found room near a map object", free)
	farm.move_building(old, target)
	await wait(2)
	var state: Dictionary = farm._to_state()
	check("a moved map object is saved as placed", not state["starting_objects"].has(name_before) \
			and state["buildings"].any(func(b: Dictionary) -> bool: return b["cell"] == target))

	# Computers don't use this.
	controls.set_active(false)
	var count: int = farm.builder.placed.size()
	await hold(screen_of(to))
	check("computers don't lift buildings", not mover.moving and farm.builder.placed.size() == count)
	touch(screen_of(to), false)
	saves.farm_state = {}

	print("ALL PASS" if fails == 0 else "%d FAILED" % fails)
	quit(fails)
