extends SceneTree
## The wardthorn is rare: it costs a lot, the stall has one a day, it needs room, and only
## walking up and tapping the plant bursts it.
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
	e.index = 1
	e.position = root.get_final_transform() * at
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func tap(at: Vector2) -> void:
	touch(at, true)
	await wait(2)
	touch(at, false)
	await wait(2)


func stand(cell: Vector2i) -> void:
	var g: TileMapLayer = farm.ground
	player.global_position = g.to_global(g.map_to_local(cell)) + Vector2(0, 4)
	player.facing = 3
	await wait(30)


## Where the plant's art shows on the screen.
func screen_of(crop: Node2D) -> Vector2:
	return root.get_canvas_transform() * (crop.global_position + Vector2(0, -20))


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
	var hud: Node = main.get_node("HUD")
	var controls: Node = main.get_node("HUD/TouchControls")
	var pick: Control = main.get_node("HUD/PickMenu")
	var shop: Control = main.get_node("HUD/ShopMenu")
	var ward: CropData = inv.crop_by_id(&"wardthorn")
	var radish: CropData = inv.CROPS[0]

	# Buying.
	check("it costs far more than other seeds", ward.seed_price > inv.crop_by_id(&"pumpkin").seed_price * 2)
	inv.money = ward.seed_price * 3
	check("the first sells", inv.buy_seed(ward) and inv.seed_count(ward) == 1)
	check("the stall has one a day", not inv.buy_seed(ward) and inv.seed_count(ward) == 1 and inv.money == ward.seed_price * 2)
	check("other seeds have no limit", inv.buy_seed(radish) and inv.buy_seed(radish))
	shop.open()
	await wait(2)
	var row: int = inv.CROPS.find(ward)
	check("the shop says it's sold out", shop._buttons[row].disabled and shop._buttons[row].text == "Sold out")
	shop.close()
	await wait(2)
	progress.end_day()
	check("the stall restocks in the morning", inv.seeds_left_today(ward) == ward.daily_stock)
	inv.seeds[ward.id] = 3

	# Space.
	var center := Vector2i(24, 14)
	var beside := center + Vector2i.RIGHT
	player.seed_index = inv.CROPS.find(ward)
	farm.till(center)
	farm.till(beside)
	farm.plant(beside, radish)
	await wait(2)
	check("a crop beside the spot blocks it", not farm.can_use(2, center))
	check("and it says why", farm.ward_room_status(center).contains("clear"))
	farm.crops[beside].queue_free()
	farm.crops.erase(beside)
	farm.untill(beside)
	await wait(2)
	check("with room it can be planted", farm.can_use(2, center))
	farm.plant(center, ward)
	farm._refresh_crop_needs()
	await wait(2)
	check("facing a claimed tile explains it", farm.ward_space_status(beside).contains("belongs to the wardthorn"))
	check("other tiles say nothing", farm.ward_space_status(center + Vector2i(2, 0)).is_empty())
	var first_lean: float = farm.crops[center].sprite.skew
	await wait(30)
	check("it sways, even as a seed", farm.crops[center].sprite.skew != first_lean)
	check("the tiles around it can't be farmed", not farm.is_farmable(beside) and not farm.is_farmable(center + Vector2i(1, 1)))
	check("or built on", not farm.can_build(beside))
	check("two tiles away is fine", farm.is_farmable(center + Vector2i(2, 0)))
	farm.till(center + Vector2i(2, 0))
	check("but another wardthorn needs its own room", not farm.can_use(2, center + Vector2i(2, 0)))
	player.seed_index = 0
	check("a plain crop can go two tiles away", farm.can_use(2, center + Vector2i(2, 0)))
	farm.untill(center + Vector2i(2, 0))

	# Bursting.
	var crop: Node2D = farm.crops[center]
	crop.set_days_grown(ward.days_to_grow)
	farm._refresh_crop_needs()
	await stand(center + Vector2i.LEFT)
	farm.run_action()
	check("the big button leaves it", farm.crops.has(center))
	var water: int = inv.holy_water
	farm.run_heal()
	check("the bottle leaves it too", farm.crops.has(center) and inv.holy_water <= water)

	controls.set_active(true)
	await stand(center + Vector2i(-6, 0))
	await tap(screen_of(crop))
	check("from far away it won't", not pick.visible and farm.crops.has(center))
	check("and it says to walk closer", hud.latest_notice().contains("closer") or hud._waiting_notices.any(func(n: String) -> bool: return n.contains("closer")))
	await stand(center + Vector2i(-2, 0))
	touch(screen_of(crop), true)
	await wait(2)
	var e := InputEventScreenDrag.new()
	e.index = 1
	e.position = root.get_final_transform() * (screen_of(crop) + Vector2(40, 0))
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await wait(2)
	touch(screen_of(crop) + Vector2(40, 0), false)
	await wait(2)
	check("a slide doesn't count", not pick.visible)
	await tap(screen_of(crop))
	check("close by, a tap asks first", pick.visible and farm.crops.has(center))
	check("keeping it comes first", pick._rows.get_child(0).text.contains("Keep"))
	pick._rows.get_child(0).pressed.emit()
	await wait(2)
	check("keeping it keeps it", not pick.visible and farm.crops.has(center))
	await tap(screen_of(crop))
	pick._rows.get_child(1).pressed.emit()
	await wait(2)
	check("bursting bursts it", not farm.crops.has(center))
	check("the space opens up again", farm.is_farmable(beside))
	check("and says nothing now", farm.ward_space_status(beside).is_empty())

	# Buttons come first.
	check("taps on the buttons never reach it", not controls.is_free_spot(Vector2(596, 296)))

	print("ALL PASS" if fails == 0 else "%d FAILED" % fails)
	quit(fails)
