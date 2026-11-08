extends SceneTree
## Storage controls (docs/28_...): a limited bag filled at the storage chest, one item in hand
## that the big button uses, and objects used by tapping them. Runs without --classic-controls.
const RIGHT := 3
const UP := 1

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


func finger(at: Vector2, down: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = at
	e.pressed = down
	return e


func stand(cell: Vector2i, facing: int = RIGHT) -> void:
	var g: TileMapLayer = farm.ground
	player.global_position = g.to_global(g.map_to_local(cell)) + Vector2(0, 4)
	player.facing = facing
	await wait(3)


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var gs: Node = root.get_node("GameState")
	var saves: Node = root.get_node("SaveGame")
	saves.start_new_game()
	root.get_node("Progress").show_story = false
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	farm = main.get_node("Farm")
	player = main.get_node("World/Player")
	player._safe_left = 999.0
	var hud: Node = main.get_node("HUD")
	var notices: Array[String] = []
	gs.notice.connect(func(text: String) -> void: notices.append(text))
	var radish: CropData = inv.CROPS[0]
	var seed_radish: StringName = inv.seed_item(radish)

	check("storage controls are on without the test flag", gs.carry_mode)
	check("the chest stands by the house", main.has_node("World/StorageChest"))
	check("the bag starts with tools, seeds, holy water, a sword and a lantern", inv.bag_items() == [&"hoe", &"can", seed_radish, &"seed_carrot", &"seed_pumpkin", &"holy_water", &"sword", &"build_lantern_post"])
	check("and has 12 slots", inv.bag_slots == 12 and inv.used_slots() == 8)
	check("the seeds to plant start as radish, carrot and pumpkin", inv.plant_set == [seed_radish, &"seed_carrot", &"seed_pumpkin"])
	check("the sword is ready in the combat set", inv.has_sword and inv.combat_set == [&"sword"])
	check("a lantern post is ready in the build set", inv.build_set == [&"build_lantern_post"])
	inv.give_starter_kit()
	check("the kit is only given once", inv.building_count(inv.building_by_id(&"lantern_post")) == 1)
	check("the corner hides holy water", not hud.status_rows.get_node("holy_water").visible)
	check("healing keeps its picture", hud.status_rows.get_node("healed").visible and hud.status_rows.get_node("healed/Icon").visible)
	# The rest of this test starts from the old 8 kinds with no sword or lantern.
	inv.has_sword = false
	inv.bag.erase(&"sword")
	inv.combat_set.clear()
	inv.buildings.clear()
	inv.bag.erase(&"build_lantern_post")
	inv.build_set.clear()
	inv.bag_slots = 8
	check("farming mode first", player.mode == 0 and hud.tool_label.text.begins_with("Farming"))

	# The big button farms smartly, with what the farming set holds.
	var cell := Vector2i(23, 16)
	await stand(cell + Vector2i.LEFT)
	await press("action")
	check("it tills", farm.is_tilled(cell))
	await press("action")
	check("then plants the first seed in the set", farm.crops.has(cell) and farm.crops[cell].data == radish and inv.carried(seed_radish) == 9)
	await press("action")
	check("then waters", farm.is_watered(cell))

	# Only what's in the set, and carried, is used.
	var cell2 := Vector2i(23, 18)
	farm.till(cell2)
	await stand(cell2 + Vector2i.LEFT)
	check("taking radish out of its box", inv.toggle_in_set(seed_radish) and not inv.plant_set.has(seed_radish))
	await press("action")
	check("plants the next seed in the set", farm.crops.has(cell2) and farm.crops[cell2].data.id == &"carrot")
	inv.toggle_in_set(seed_radish)
	check("adding it back puts it in the last box", inv.plant_set.back() == seed_radish)
	check("put away moves seeds to storage", inv.put(seed_radish) and inv.carried(seed_radish) == 0 and inv.stored(seed_radish) == 9)
	check("they stay in their box", inv.plant_set.has(seed_radish) and not inv.ready_now(inv.plant_set).has(seed_radish))
	check("take brings them back", inv.take(seed_radish) and inv.carried(seed_radish) == 9 and inv.stored(seed_radish) == 0)
	var grass := Vector2i(23, 22)
	await stand(grass + Vector2i.LEFT)
	inv.toggle_job(&"till")
	check("Till off: no tilling", farm.smart_action(grass) == 0)
	inv.toggle_job(&"till")
	check("Till on: it tills", farm.smart_action(grass) == 7)
	check("crops can't go in a set", not inv.can_set(&"crop_radish"))

	# Farm jobs switch the big button's jobs on and off.
	check("every farm job starts on", inv.FARM_JOBS.all(func(j: StringName) -> bool: return inv.farm_jobs.has(j)))
	var ripe_kept := Vector2i(26, 18)
	farm.till(ripe_kept)
	farm._add_crop(ripe_kept, radish).set_days_grown(radish.days_to_grow)
	await stand(ripe_kept + Vector2i.LEFT)
	inv.toggle_job(&"harvest")
	check("Harvest off leaves a ripe crop alone", farm.smart_action(ripe_kept) == 0)
	await press("action")
	check("and it stays in the ground", farm.crops.has(ripe_kept))
	inv.toggle_job(&"harvest")
	check("Harvest on picks it again", farm.smart_action(ripe_kept) == 3)
	farm.crops[ripe_kept].queue_free()
	farm.crops.erase(ripe_kept)
	farm.untill(ripe_kept)
	for job: StringName in [&"till", &"plant", &"harvest", &"gather", &"heal"]:
		inv.toggle_job(job)
	check("water only: no tilling", farm.smart_action(ripe_kept) == 0)
	farm.till(ripe_kept)
	await wait(2)
	check("water only: no planting", farm.smart_action(ripe_kept) == 0)
	farm._add_crop(ripe_kept, radish)
	check("water only: it waters", farm.smart_action(ripe_kept) == 4)
	inv.farm_jobs = inv.FARM_JOBS.duplicate()
	farm.crops[ripe_kept].queue_free()
	farm.crops.erase(ripe_kept)
	farm.untill(ripe_kept)

	# Ripe crops are always harvested.
	var ripe := Vector2i(23, 20)
	farm.till(ripe)
	var crop: Node = farm._add_crop(ripe, radish)
	crop.set_days_grown(radish.days_to_grow)
	await stand(ripe + Vector2i.LEFT)
	check("the button shows harvest", farm.smart_action(ripe) == 3)
	await press("action")
	check("it harvests into the bag", not farm.crops.has(ripe) and inv.carried(&"crop_radish") == 1)

	# Combat mode uses the combat set.
	await press("switch_mode")
	check("C switches to combat", player.mode == 1 and hud.tool_label.text.contains("no weapon"))
	check("with no weapon it does nothing", farm.smart_action(ripe) == 0)
	await press("action")
	check("and says why", notices.back().contains("No weapon"))
	inv.has_sword = true
	inv.bag[&"sword"] = 1
	inv.toggle_in_set(&"sword")
	check("the sword goes on combat button 1", inv.combat_item(0) == &"sword" and farm.weapon() == &"sword")
	inv.toggle_in_combat_slot(&"sword", 1)
	check("a weapon is on one button only: adding it moves it", inv.combat_slot(0).is_empty() and inv.combat_slot(1) == [&"sword"])
	check("and the pick follows to a button with a weapon", inv.combat_pick == 1 and farm.weapon() == &"sword")
	check("then the button swings", farm.smart_action(ripe) == 1)
	await press("action")
	check("a swing happens", player.sword._busy)
	await wait(20)
	inv.pick_combat(0)
	check("an empty button can't be picked", inv.combat_pick == 1)
	inv.toggle_in_combat_slot(&"sword", 0)
	await press("seed_next")
	check("E only stops on buttons with a weapon", inv.combat_pick == 0)
	player.set_mode(0)
	check("back to farming", player.mode == 0)
	inv.bag.erase(&"sword")
	inv.has_sword = false
	inv.combat_set.clear()

	# A full bag sends new things to storage.
	var wood: MaterialData = inv.MATERIALS[0]
	var stone: MaterialData = inv.MATERIALS[1]
	inv.add_material(wood, 2)
	check("wood fills slot 8", inv.used_slots() == 8 and inv.carried(inv.material_item(wood)) == 2)
	inv.add_material(stone, 3)
	check("stone goes to storage", inv.stored(inv.material_item(stone)) == 3 and inv.carried(inv.material_item(stone)) == 0)
	check("with a notice", notices.any(func(n: String) -> bool: return n.contains("bag is full")))
	inv.add_material(wood, 1)
	check("a kind already carried still stacks", inv.carried(inv.material_item(wood)) == 3)
	check("a full bag can't take a new kind", not inv.take(inv.material_item(stone)))

	# Shipping takes only what's carried.
	inv.add_harvest(radish)
	inv.put(&"crop_radish", 1)
	inv.ship_all()
	check("one carried radish shipped", inv.shipped.get(&"radish", 0) == 1 and inv.harvest_count(radish) == 1)
	check("the stored one stays", inv.stored(&"crop_radish") == 1)

	# Crafting uses everything owned, and the bag never holds more than is owned.
	inv.materials[wood.id] = 1
	inv._tidy_bag()
	check("the bag follows the total down", inv.carried(inv.material_item(wood)) == 1)

	# Objects are tapped, standing close.
	var chest: Area2D = main.get_node("World/StorageChest/Interact")
	await stand(Vector2i(20, 20))
	check("a far tap says to walk closer", farm.ward_tap.tap_object(chest.global_position) and notices.back().contains("Walk closer"))
	player.global_position = chest.global_position + Vector2(0, 26)
	player.facing = UP
	await wait(3)
	var menu: Node = hud.get_node("StorageMenu")
	check("a close tap opens storage", farm.ward_tap.tap_object(chest.global_position) and menu.visible)
	check("storage lists the stone", menu.rows_text.contains("Stone: bag 0, stored 3"))
	menu.close()
	await wait(2)
	check("the big button doesn't use objects", farm.smart_action(farm.target_cell_for(player)) != 2)

	# Bigger bag.
	inv.money = 1000
	check("the bag upgrades at the stall", inv.upgrade_bag() and inv.bag_slots == 12)
	inv.upgrade_bag()
	inv.upgrade_bag()
	check("up to the most", not inv.upgrade_bag() and inv.bag_slots == 20)

	# Build mode places the build set's first building; moving is picking up, then placing.
	var lantern: BuildingData = inv.building_by_id(&"lantern_post")
	var lantern_item: StringName = inv.building_item(lantern)
	inv.add_building(lantern, 1)
	check("a new building goes in the build set", inv.build_set == [lantern_item])
	await press("switch_mode")
	await press("switch_mode")
	check("C steps Farm, Combat, Build", player.mode == 2 and player.tool == 5)
	check("the line names the building", hud.tool_label.text.begins_with("Build: Lantern post"))
	var spot := Vector2i(23, 22)
	await stand(spot + Vector2i.LEFT)
	check("the button would place it", farm.smart_action(spot) == 8)
	await press("action")
	check("it's placed", farm.builder.placed.has(spot) and inv.carried(lantern_item) == 0)
	check("an empty set says so", hud.tool_label.text.contains("nothing in the build set"))
	check("no guard square with nothing to place", farm._placing_guard_radius() == 0)
	inv.set_build_tool(&"pick_up")
	check("the button would pick it up", farm.smart_action(spot) == 9)
	var slots: int = inv.bag_slots
	inv.bag_slots = inv.used_slots()
	await press("action")
	check("a full bag won't pick it up", farm.builder.placed.has(spot) and notices.back().contains("bag is full"))
	inv.bag_slots = slots
	await press("action")
	check("picked up into the bag", not farm.builder.placed.has(spot) and inv.carried(lantern_item) == 1)
	check("and to the front of the set", inv.build_set[0] == lantern_item)

	# Build mode does one thing at a time: Place, Move or Pick up.
	inv.set_build_tool(&"place")
	await press("action")
	check("it's placed again", farm.builder.placed.has(spot))
	check("Place doesn't pick up", farm.smart_action(spot) == 0)
	await press("build_tool")
	check("V goes to Move", inv.build_tool == &"move" and hud.tool_label.text.begins_with("Move"))
	check("the button would lift it", farm.smart_action(spot) == farm.Action.MOVE)
	await press("action")
	check("lifted, not in the bag", farm.lifted == spot and inv.carried(lantern_item) == 0)
	var to := spot
	for offset: Vector2i in [Vector2i(0, 2), Vector2i(0, -2), Vector2i(2, 0), Vector2i(-2, 2), Vector2i(2, 2)]:
		if to == spot and farm.can_move(spot, spot + offset):
			to = spot + offset
	check("there's a free spot to move to", to != spot)
	check("the button would put it down", farm.smart_action(to) == farm.Action.PUT_DOWN)
	farm._run_carry(farm.smart_action(to), to)
	check("moved", farm.builder.placed.has(to) and not farm.builder.placed.has(spot) and farm.lifted == farm.builder.NO_CELL)
	farm._run_carry(farm.Action.MOVE, to)
	await press("build_tool")
	await wait(1)
	check("changing tool puts a lifted one back", farm.lifted == farm.builder.NO_CELL and inv.build_tool == &"pick_up")
	check("Pick up picks it up", farm.smart_action(to) == farm.Action.PICK_UP)
	farm._run_carry(farm.Action.PICK_UP, to)
	check("picked up into the bag again", not farm.builder.placed.has(to) and inv.carried(lantern_item) == 1)
	check("Pick up never places", farm.smart_action(spot) == 0)
	await press("build_tool")
	check("V wraps round to Place", inv.build_tool == &"place" and farm.smart_action(spot) == 8)
	await press("tool_1")
	check("1 jumps back to Farm", player.mode == 0 and player.tool == 0)

	# New kinds join their set, except rare ward seeds.
	inv.strong_holy_water += 1
	inv._carry(&"strong_holy_water", 1)
	check("strong holy water is carried, not set", inv.carried(&"strong_holy_water") == 1 and not inv.can_set(&"strong_holy_water"))
	inv.seeds[&"wardthorn"] = 1
	inv._carry(&"seed_wardthorn", 1)
	check("new seeds are carried but not planted", inv.carried(&"seed_wardthorn") == 1 and not inv.plant_set.has(&"seed_wardthorn"))
	inv.toggle_in_set(&"seed_wardthorn")
	check("any seed can be added, a 4th too", inv.plant_set.back() == &"seed_wardthorn" and inv.plant_set.size() == 4)
	inv.toggle_in_set(&"seed_wardthorn")
	check("and taken out again", not inv.plant_set.has(&"seed_wardthorn"))

	# Texts that changed with these controls.
	var guide: Node = hud.get_node("GoalGuide")
	check("the heal lesson names the big button", guide._step_text(["heal", "old", "old"]).contains("press R"))
	check("the ship lesson says to click the box", guide._step_text(["ship", "old", "old"]).contains("click the shipping box"))
	var box: Area2D = main.get_node("World/ShippingBox/Interact")
	box.interact(player)
	check("an empty bag says what to carry", notices.back().contains("Carry crops"))

	# Every morning starts in Farm mode.
	player.set_mode(1)
	root.get_node("Progress").end_day()
	await wait(2)
	check("a new day starts in Farm mode", player.mode == 0)

	# Phones swap Heal and Seed for the mode button.
	var touch: Node = hud.get_node("TouchControls")
	touch.set_active(true)
	await wait(2)
	for action: String in ["heal", "seed_menu"]:
		check("no %s button" % action, not touch._buttons[action].visible)
	check("a mode button and a Bag button", touch._buttons["switch_mode"].visible and touch._buttons["inventory"].visible)
	check("no tool bar", not hud.get_node("KeyToolBar").visible)
	inv.has_sword = true
	if inv.carried(&"sword") == 0:
		inv._carry(&"sword", 1)
	inv.combat_set.assign([&"sword"])
	inv.inventory_changed.emit()
	player.set_mode(1)
	check("the mode button shows the combat icon", touch._mode_icon.texture.region.position.x == 32.0)
	check("combat mode shows the buttons that have a weapon", touch._buttons["combat_slot_1"].visible and not touch._buttons["combat_slot_2"].visible and not touch._buttons["combat_slot_3"].visible)
	touch._buttons["combat_slot_1"].pressed.emit()
	check("tapping a combat button picks it, and it glows", inv.combat_pick == 0 and touch._buttons["combat_slot_1"].modulate == touch.SELECTED_COLOR)
	inv.pick_combat(0)
	player.set_mode(0)
	check("the combat buttons hide outside combat", not touch._buttons["combat_slot_1"].visible and not touch._buttons["combat_slot_2"].visible and not touch._buttons["combat_slot_3"].visible)
	player.set_mode(2)
	inv.set_build_tool(&"place")
	touch._shown_action = 0
	touch._update_action_button()
	check("Build mode keeps the building's picture on a taken spot, only dimmed", inv.ready_now(inv.build_set).is_empty() or touch._action_icon.texture == player.selected_building().preview_texture)
	player.set_mode(0)
	check("no Build X with storage controls", not touch._buttons["build_mode"].visible)

	# Holding the mode button opens the wheel; sliding to Build and letting go picks it.
	var mode_button: TouchScreenButton = touch._buttons["switch_mode"]
	var center: Vector2 = mode_button.global_position + mode_button.texture_normal.get_size() * mode_button.scale / 2.0
	touch._input(finger(center, true))
	await create_timer(touch.WHEEL_HOLD_SECONDS + 0.1).timeout
	await process_frame
	check("holding opens the wheel", touch._wheel.visible and player.mode == 0)
	var build_at: Vector2 = touch._wheel_slots[2].global_position
	var slide := InputEventScreenDrag.new()
	slide.position = build_at
	touch._input(slide)
	touch._input(finger(build_at, false))
	check("sliding to Build picks it", player.mode == 2 and not touch._wheel.visible)
	touch._input(finger(center, true))
	await process_frame
	touch._input(finger(center, false))
	check("a quick tap goes to the next mode", player.mode == 0 and not touch._wheel.visible)
	touch._input(finger(center, true))
	await create_timer(touch.WHEEL_HOLD_SECONDS + 0.1).timeout
	await process_frame
	touch._input(finger(center + Vector2(0, 60), false))
	check("letting go off the wheel changes nothing", player.mode == 0 and not touch._wheel.visible)

	# The bag page lists the carried items and both sets.
	var sets: Node = hud.get_node("SetsMenu")
	await press("inventory")
	check("I opens the bag page", sets.visible and sets.carried_text.contains("Hoe"))
	await process_frame
	check("the buttons wait under a menu", touch._buttons["action"].is_visible_in_tree() and touch._buttons["switch_mode"].is_visible_in_tree() and not touch._buttons["action"].can_process())
	sets.show_page("Modes")
	check("the Modes page lists the seeds to plant", sets.plant_text.contains("Radish seeds 9"))
	check("combat buttons stay set when a weapon is put away", sets.combat_text.contains("1: Sword"))
	check("the build set lists the lantern", sets.build_text.contains("Lantern post 1"))
	await press("inventory")
	check("I closes it", not sets.visible)
	await press("inventory")
	sets.get_node("CloseOverlay/CloseButton").pressed.emit()
	check("the X closes it", not sets.visible)
	var bag_button: TouchScreenButton = touch._buttons["inventory"]
	check("the Bag sits above the mode button", bag_button.position.y < touch._buttons["switch_mode"].position.y and bag_button.scale.x < 0.6)
	var mode_at: Vector2 = touch._buttons["switch_mode"].position + Vector2(21, 21)
	var bag_at: Vector2 = bag_button.position + Vector2(17, 17)
	check("the Bag is clear of the wheel", touch.WHEEL_OFFSETS.all(func(o: Vector2) -> bool: return (mode_at + o).distance_to(bag_at) > 40.0))
	touch.set_active(false)

	# Saving keeps the bag; older saves fill it.
	inv.toggle_job(&"gather")
	var file := ConfigFile.new()
	inv.save_to(file)
	# A copy, as a real save on disk is: the file would otherwise share the dictionaries reset() clears.
	file.parse(file.encode_to_text())
	var saved_items: Array = inv.bag_items()
	var saved_jobs: Array = inv.farm_jobs.duplicate()
	inv.reset()
	inv.load_from(file)
	check("the bag comes back", inv.bag_items() == saved_items and inv.bag_slots == 20)
	check("the farm jobs come back", inv.farm_jobs == saved_jobs and not inv.farm_jobs.has(&"gather"))
	check("the combat button assignments come back", inv.combat_slot(0) == [&"sword"])
	file.erase_section_key("game", "bag")
	file.set_value("game", "bag_slots", 8)
	inv.load_from(file)
	check("an old save carries tools first", inv.bag_items().slice(0, 2) == [&"hoe", &"can"] and inv.bag_items().has(&"holy_water"))
	check("an old small bag grows to the new start", inv.bag_slots == 12)
	file.erase_section_key("game", "plant_set")
	file.set_value("game", "farm_set", [&"hoe", &"seed_radish", &"can", &"seed_carrot"])
	inv.load_from(file)
	check("an old farming set moves its seeds to plant", inv.plant_set == [&"seed_radish", &"seed_carrot"])
	check("and fills what fits", inv.used_slots() == mini(12, inv.all_items().filter(func(i: StringName) -> bool: return inv.total(i) > 0).size()))

	print("Done: %d failed" % fails)
	quit(1 if fails > 0 else 0)
