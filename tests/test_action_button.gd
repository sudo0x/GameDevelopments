extends SceneTree
## The Action key and button: a day's farming with no tool change, asking before sleep,
## swinging at what's close, and the button's icon. What Action chooses is in test_smart_action.
const DOWN := 0
const UP := 1
const LEFT := 2
const RIGHT := 3
const HOE := 0
const HOLY_WATER := 4
const BUILD := 5
const ACTION_AT := Vector2(596, 296)

var fails := 0
var farm: Node
var player: Node


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


func touch(at: Vector2, finger: int, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = finger
	e.position = root.get_final_transform() * at
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func tap(at: Vector2, finger: int) -> void:
	touch(at, finger, true)
	await wait(2)
	touch(at, finger, false)
	await wait(2)


func stand(cell: Vector2i, facing: int) -> void:
	var g: TileMapLayer = farm.ground
	player.global_position = g.to_global(g.map_to_local(cell)) + Vector2(0, 4)
	player.facing = facing
	await wait(3)


func stand_on(area: Node2D) -> void:
	player.global_position = area.global_position + Vector2(0, 5)
	await wait(3)


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	farm = main.get_node("Farm")
	player = main.get_node("World/Player")
	player._safe_left = 999.0
	var controls: Node = main.get_node("HUD/TouchControls")
	var sleep: Control = main.get_node("HUD/SleepMenu")
	var shop: Control = main.get_node("HUD/ShopMenu")
	var bag: Control = main.get_node("HUD/BagMenu")
	var door: Node2D = main.get_node("World/House/Door")
	var stall: Node2D = main.get_node("World/ShopStall/Interact")
	var box: Node2D = main.get_node("World/ShippingBox/Interact")
	var radish: CropData = inv.CROPS[0]

	# A day's farming with the hoe still selected.
	await stand(Vector2i(22, 14), RIGHT)
	var cell := Vector2i(23, 14)
	check("the test tile is free", farm.is_farmable(cell))
	await press("action")
	check("Action tills", farm.is_tilled(cell))
	var seeds_before: int = inv.seed_count(radish)
	await press("action")
	check("Action plants", farm.crops.has(cell) and inv.seed_count(radish) == seeds_before - 1)
	await press("action")
	check("Action waters", farm.is_watered(cell))
	await press("action")
	check("nothing more to do changes nothing", farm.crops.has(cell) and farm.is_watered(cell))
	farm.crops[cell].set_days_grown(radish.days_to_grow)
	await press("action")
	check("Action harvests", not farm.crops.has(cell) and inv.harvest_count(radish) == 1)
	check("the selected tool never changed", player.tool == HOE)
	check("the guide heard all of it", progress.guide_done.has("till") and progress.guide_done.has("plant") \
			and progress.guide_done.has("water") and progress.guide_done.has("harvest"))

	# Gathering takes several presses.
	var spot := Vector2i(-1, -1)
	for c: Vector2i in farm.gathering.spots:
		if farm.gathering.can_hit(c) and farm.is_farmable(c + Vector2i.LEFT):
			spot = c
			break
	await stand(spot + Vector2i.LEFT, RIGHT)
	var gather: GatherData = farm.gathering.spots[spot].data
	for i in gather.hits:
		await press("action")
	check("Action gathers", farm.gathering.spots[spot].gathered)

	# Aim: a tile with work ahead wins, tiles beside can help, but they never get tilled.
	var a := Vector2i(30, 14)
	await stand(a + Vector2i.LEFT, RIGHT)
	farm.till(a)
	farm.plant(a, radish)
	farm.water(a)
	await wait(2)
	check("no work ahead, and grass beside isn't picked", farm.action_target_for(player) == a)
	await press("action")
	check("the grass beside stays grass", not farm.is_tilled(a + Vector2i.UP) and not farm.is_tilled(a + Vector2i.DOWN))
	farm.till(a + Vector2i.UP)
	farm.plant(a + Vector2i.UP, radish)
	await wait(2)
	check("a dry crop beside is found", farm.action_target_for(player) == a + Vector2i.UP)
	await press("action")
	check("and watered", farm.is_watered(a + Vector2i.UP))

	# Asking before sleep.
	var day: int = progress.day
	await wait(35)
	await stand_on(door)
	await press("action")
	check("the door asks first", sleep.visible and paused and progress.day == day)
	await wait(2)
	await press("action")
	check("Action again means no", not sleep.visible and not paused)
	await wait(100)
	check("no day passed", progress.day == day)
	await press("action")
	await process_frame
	sleep._no.pressed.emit()
	check("No closes it", not sleep.visible and not paused)
	await wait(100)
	check("still no day passed", progress.day == day)
	await press("action")
	check("No has the focus", sleep._no.has_focus())
	check("the question has help", not sleep.get_node("Margin/Box/Help").text.is_empty())
	sleep._yes.pressed.emit()
	check("Yes closes it", not sleep.visible and not paused)
	await wait(100)
	check("Yes sleeps", progress.day == day + 1)
	await press("interact")
	check("F still sleeps at once", not sleep.visible)
	await wait(100)
	check("F slept", progress.day == day + 2)

	# Fast tapping along a row can't open a menu.
	var row_cell := Vector2i(21, 16)
	await stand(row_cell + Vector2i.LEFT, RIGHT)
	await press("action")
	check("a farming tap", farm.is_tilled(row_cell))
	await stand_on(stall)
	await press("action")
	check("the next quick tap doesn't open the shop", not shop.visible and not paused)
	await wait(35)
	await press("action")
	check("a tap after the pause does", shop.visible)
	await wait(2)
	await press("action")
	await wait(2)

	# Other objects.
	await stand_on(stall)
	await press("action")
	check("Action opens the shop", shop.visible)
	await wait(2)
	await press("action")
	check("Action closes the shop", not shop.visible)
	await wait(2)
	await press("inventory")
	check("the bag opens", bag.visible)
	await wait(2)
	await press("action")
	check("Action leaves the bag open", bag.visible)
	await press("inventory")
	await wait(2)
	inv.add_harvest(radish)
	await stand_on(box)
	await press("action")
	check("Action ships", inv.shipped.get(radish.id, 0) >= 1 and not inv.has_harvest())

	# A creature behind the player: turn, and really hit it.
	await stand(Vector2i(22, 16), RIGHT)
	inv.has_sword = true
	farm.spawner._spawn(player.global_position + Vector2(-34, 0), farm.spawner.CREATURES[0])
	var creature: Node = farm.spawner.creatures.back()
	await wait(1)
	var health: int = creature.health
	await press("action")
	check("the player turns to it", player.facing == LEFT)
	await wait(30)
	check("the swing hits it", not is_instance_valid(creature) or creature.health < health)
	check("the tool is still the hoe", player.tool == HOE)
	farm.spawner.clear()
	await wait(30)
	inv.has_sword = false

	# Never by accident.
	var cursed_side := Vector2i(-1, -1)
	for y in range(5, 22):
		for x in range(20, 45):
			var c := Vector2i(x, y)
			if farm.is_farmable(c) and farm.healing.is_cleansable(c + Vector2i.RIGHT):
				cursed_side = c
				break
		if cursed_side != Vector2i(-1, -1):
			break
	await stand(cursed_side, RIGHT)
	var water: int = inv.holy_water
	player.tool = HOLY_WATER
	await wait(2)
	await press("action")
	check("Action never spends holy water", inv.holy_water == water)
	player.tool = HOE
	inv.has_purifying_hoe = true
	inv.hoe_uses_left = 3
	await wait(2)
	await press("action")
	check("Action never purifies", inv.hoe_uses_left == 3 and farm.healing.is_cleansable(cursed_side + Vector2i.RIGHT))
	var fence: BuildingData = inv.building_by_id(&"fence")
	inv.add_building(fence)
	farm.builder.place(Vector2i(23, 18), fence)
	await stand(Vector2i(22, 18), RIGHT)
	await press("action")
	check("Action never picks up a building", farm.builder.placed.has(Vector2i(23, 18)))
	await stand(Vector2i(22, 20), RIGHT)
	var empty := Vector2i(23, 20)
	farm.till(empty)
	var kept: Dictionary = inv.seeds.duplicate()
	inv.seeds[radish.id] = 0
	await wait(2)
	await press("action")
	check("Action never hoes soil back", farm.is_tilled(empty))
	inv.seeds.assign(kept)
	progress.day_changing = true
	await wait(2)
	await press("action")
	check("nothing happens while the day changes", not farm.crops.has(empty))
	progress.day_changing = false

	# The button.
	controls.set_active(true)
	await wait(3)
	check("soil to plant lights the button", controls._shown_action == farm.Action.PLANT and controls._buttons["action"].modulate == Color.WHITE)
	var plant_icon: Texture2D = controls._action_icon.texture
	check("it shows the seeds", plant_icon is AtlasTexture and plant_icon.region.position.x == 2 * 36.0)
	check("the cursor follows Action", farm._shown_cell == empty)
	inv.seeds[radish.id] = 0
	await wait(3)
	check("nothing to do dims it", controls._shown_action == farm.Action.NONE and controls._buttons["action"].modulate.a < 1.0)
	inv.seeds.assign(kept)
	await wait(3)
	player.tool = BUILD
	await wait(3)
	check("the cursor follows the tool for Use", farm._shown_cell == farm.target_cell)
	player.tool = HOE

	# Finger 0 is the one phones also turn into a mouse click: one tap must do one thing.
	var count: int = inv.seed_count(radish)
	var tool_uses: Array[int] = []
	player.tool_used.connect(func(t: int) -> void: tool_uses.append(t))
	await wait(2)
	await tap(ACTION_AT, 0)
	check("a tap plants", farm.crops.has(empty) and inv.seed_count(radish) == count - 1)
	check("the tap doesn't also use the hoe", tool_uses.is_empty())
	await tap(Vector2(320, 120), 0)
	check("a tap on the world uses no tool", tool_uses.is_empty())

	await wait(35)
	await stand_on(stall)
	await wait(3)
	check("objects show the ! icon", controls._action_icon.texture == controls.ACT_ICON)
	await tap(ACTION_AT, 1)
	check("the button opens the shop", shop.visible)
	await wait(3)
	check("the button still shows ! under a menu", controls._action_icon.texture == controls.ACT_ICON and controls._buttons["action"].modulate == Color.WHITE)
	await tap(ACTION_AT, 1)
	check("and closes it", not shop.visible)
	await wait(2)
	await stand_on(door)
	await tap(ACTION_AT, 1)
	check("the button asks before sleep", sleep.visible)
	check("the question clears the Action button", sleep.get_global_rect().end.x <= 501.0)
	await tap(ACTION_AT, 1)
	check("and closes it again", not sleep.visible)

	print("ALL PASS" if fails == 0 else "%d FAILED" % fails)
	quit(fails)
