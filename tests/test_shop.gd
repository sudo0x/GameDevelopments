extends SceneTree

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

func stand(player: Node, pos: Vector2) -> void:
	player.global_position = pos
	for i in 6:
		await physics_frame

func _initialize() -> void:
	_run()

func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var player: Node = main.get_node("World/Player")
	var box: Node2D = main.get_node("World/ShippingBox")
	var stall: Node2D = main.get_node("World/ShopStall")
	var hud: Node = main.get_node("HUD")
	var menu: Control = main.get_node("HUD/ShopMenu")
	var radish: Variant = inv.CROPS[0]
	var carrot: Variant = inv.CROPS[1]
	var pumpkin: Variant = inv.CROPS[2]
	print("prices: ", radish.seed_price, "/", radish.sell_price, " ", carrot.seed_price, "/", carrot.sell_price, " ", pumpkin.seed_price, "/", pumpkin.sell_price)

	# Shipping, reached from each side of the box.
	inv.harvest[&"radish"] = 2
	inv.harvest[&"pumpkin"] = 1
	await stand(player, box.global_position + Vector2(0, 16))
	await press("interact")
	check("ship from below: harvest emptied", inv.harvest.is_empty())
	check("shipped counts", inv.shipped.get(&"radish", 0) == 2 and inv.shipped.get(&"pumpkin", 0) == 1)
	check("no money before sleeping", inv.money == 0)
	var expected: int = radish.sell_price * 2 + pumpkin.sell_price
	check("shipped value", inv.shipped_value() == expected)
	check("HUD shows shipping", hud.status_text.contains("Shipping: %d" % expected))
	for offset: Variant in [Vector2(-30, -2), Vector2(30, -2), Vector2(0, -16)]:
		inv.harvest[&"carrot"] = 1
		await stand(player, box.global_position + offset)
		await press("interact")
		check("ship from side %s" % str(offset), inv.harvest.is_empty())
	expected += carrot.sell_price * 3

	progress.end_day()
	check("paid overnight", inv.money == expected)
	check("box emptied", inv.shipped.is_empty())
	check("HUD money", hud.money_label.text == str(expected))
	check("HUD shipping line gone", not hud.status_text.contains("Shipping"))
	progress.end_day()
	check("not paid twice", inv.money == expected)

	# Solid: the player can't walk through the box.
	await stand(player, box.global_position + Vector2(0, 20))
	var y0: float = player.global_position.y
	Input.action_press("move_up")
	for i in 60:
		await physics_frame
	Input.action_release("move_up")
	check("box blocks walking", player.global_position.y > box.global_position.y - 2 and player.global_position.y < y0)

	# Shop.
	await stand(player, stall.global_position + Vector2(0, 16))
	await press("interact")
	check("shop opens", menu.visible and paused)
	var buttons: Array = menu._buttons
	check("a button has focus", buttons[0].has_focus())
	var money0: int = inv.money
	var seeds0: int = inv.seed_count(radish)
	buttons[0].pressed.emit()
	check("bought radish seed", inv.money == money0 - radish.seed_price and inv.seed_count(radish) == seeds0 + 1)
	check("shop rows updated", menu._labels[0].text == "Radish seeds: %d" % (seeds0 + 1))
	await press("interact")
	check("F closes shop", not menu.visible and not paused)
	await physics_frame
	check("stays closed", not menu.visible)
	await press("interact")
	check("reopens", menu.visible and paused)
	await press("ui_cancel")
	check("Esc closes shop", not menu.visible and not paused)

	# Can't overspend.
	inv.money = radish.seed_price - 1
	var before: int = inv.seed_count(radish)
	check("buy refused", not inv.buy_seed(radish) and inv.seed_count(radish) == before and inv.money == radish.seed_price - 1)
	await press("interact")
	check("button disabled when broke", buttons[0].disabled and buttons[2].disabled)
	await press("interact")

	# The door still works.
	var house: Node2D = main.get_node("World/House")
	var day0: int = progress.day
	await stand(player, house.global_position + Vector2(0, 24))
	await press("interact")
	for i in 90:
		await physics_frame
	check("door still sleeps", progress.day == day0 + 1)

	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
