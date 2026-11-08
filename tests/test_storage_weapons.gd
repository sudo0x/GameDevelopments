extends SceneTree
## The six basic weapons (docs/28_..., finding 98): made at the workbench, they go on combat
## buttons, melee ones swing with their own picture and numbers, throwing ones spend a stone,
## and the torch burns out. Runs without --classic-controls.
const RIGHT := 3

var fails := 0


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


## A body that counts hits, standing in for a creature.
func make_dummy() -> StaticBody2D:
	var script := GDScript.new()
	script.source_code = "extends StaticBody2D\nvar hits := 0\nfunc take_hit(damage: int, _direction: Vector2) -> void:\n\thits += damage\n"
	script.reload()
	var dummy := StaticBody2D.new()
	dummy.set_script(script)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	dummy.add_child(shape)
	return dummy


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	root.get_node("SaveGame").start_new_game()
	root.get_node("Progress").show_story = false
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var farm: Node = main.get_node("Farm")
	var player: Node2D = main.get_node("World/Player")
	var hud: Node = main.get_node("HUD")
	player._safe_left = 999.0
	inv.bag_slots = 20

	# Making them.
	inv.materials[&"wood"] = 40
	inv.materials[&"stone"] = 20
	inv.materials[&"curse_shard"] = 5
	inv._carry(&"mat_stone", 20)
	var ids := ["club", "pitchfork", "sickle", "torch", "sling", "stones"]
	var made := 0
	for recipe: RecipeData in inv.RECIPES:
		if recipe.result == RecipeData.Result.BASIC_WEAPON and inv.craft(recipe):
			made += 1
			check("%s only once" % recipe.display_name, not inv.can_craft(recipe))
	check("all six can be made", made == 6 and inv.basic_weapons.size() == 6)
	for id: String in ids:
		check("%s is carried and named" % id, inv.carried(StringName(id)) == 1 and inv.item_name(StringName(id)) != id)
	check("new weapons fill the empty combat buttons", inv.combat_item(1) == &"club" and inv.combat_item(2) == &"pitchfork")
	check("stones were spent on the recipes", inv.carried(&"mat_stone") == 16)

	# A button of three: club, sickle, torch.
	inv.combat_slot(1).assign([&"club", &"sickle", &"torch"])
	inv.pick_combat(1)
	player.set_mode(1)
	var g: TileMapLayer = farm.ground
	player.global_position = g.to_global(g.map_to_local(Vector2i(22, 18))) + Vector2(0, 4)
	player.facing = RIGHT
	await wait(3)
	var cell: Vector2i = farm.target_cell_for(player)
	check("the club swings", farm.smart_action(cell) == farm.Action.SWING)
	await press("action")
	check("with the club's picture and reach", player.sword._busy and player.sword.blade.texture is AtlasTexture and player.sword.shape.radius == 18.0)
	check("the hand line names it", hud.tool_label.text == "Combat 2: Wooden club")
	await wait(40)
	inv.tap_combat(1)
	inv.tap_combat(1)
	check("two taps reach the torch", farm.weapon() == &"torch")
	await press("action")
	check("a torch swing burns", inv.torch_left == 19)
	await wait(30)
	for i in 19:
		inv.burn_torch()
	check("the torch burns out and leaves its button", not inv.basic_weapons.has(&"torch") and inv.carried(&"torch") == 0 and not inv.combat_slot(1).has(&"torch"))
	var torch_recipe: RecipeData = inv.RECIPES.filter(func(r: RecipeData) -> bool: return r.weapon == &"torch")[0]
	check("and can be made again", inv.can_craft(torch_recipe))

	# Throwing.
	inv.combat_slot(0).assign([&"sling"])
	inv.combat_turn[0] = 0
	inv.pick_combat(0)
	check("the sling throws", farm.smart_action(cell) == farm.Action.SHOOT)
	var dummy := make_dummy()
	main.get_node("World").add_child(dummy)
	dummy.global_position = player.bow.global_position + Vector2(60, 0)
	await wait(2)
	await press("action")
	check("a throw spends a stone", inv.carried(&"mat_stone") == 15)
	await press("action")
	check("no second throw while it cools down", inv.carried(&"mat_stone") == 15)
	await wait(40)
	check("the pebble hits", dummy.hits == 1)
	dummy.queue_free()
	inv.bag[&"mat_stone"] = 0
	inv._tidy_bag()
	check("no stones: nothing to throw", farm.weapon() == &"" and farm.smart_action(cell) == farm.Action.NONE)

	# Phones: an empty combat button shows a plus and opens the setup; the big button keeps one picture.
	var touch: Node = hud.get_node("TouchControls")
	touch.set_active(true)
	inv.combat_slot(2).clear()
	inv.inventory_changed.emit()
	await wait(2)
	check("an empty combat button is hidden in play", not touch._buttons["combat_slot_3"].visible)
	inv.combat_slot(1).assign([&"club", &"sickle"])
	inv.combat_turn[1] = 1
	inv.inventory_changed.emit()
	await wait(2)
	var dots: Array = touch._combat_dots[1]
	check("a button with two weapons shows two dots, the second bright", dots[0].visible and dots[1].visible and not dots[2].visible and dots[1].get_child(0).color == touch.DOT_ON_COLOR)
	check("a button with one weapon shows none", not touch._combat_dots[0][0].visible)
	var sets: Node = hud.get_node("SetsMenu")
	sets.open_on("Modes", "Combat mode")
	sets.pick(&"slot2_0")
	check("the picker offers only free weapons, by short name", sets.details_text.contains("[Fork]") and not sets.details_text.contains("[Sling]"))
	sets.close()
	inv._carry(&"mat_stone", 3)
	inv.materials[&"stone"] = 3
	await wait(2)
	check("the big button keeps one picture in combat", touch._action_icon.texture == touch.attack_icon())

	# Leaving Combat mode doesn't leave the attack picture on the big button.
	player.set_mode(0)
	await wait(3)
	check("Farm mode never keeps the attack picture", touch._action_icon.texture != touch.attack_icon())
	player.set_mode(1)

	# Saving.
	var file := ConfigFile.new()
	inv.save_to(file)
	file.parse(file.encode_to_text())
	inv.reset()
	inv.load_from(file)
	check("the weapons are saved", inv.basic_weapons.size() == 5 and inv.has_method("is_weapon") and inv.is_weapon(&"sling"))

	print("Done: %d failed" % fails)
	quit(1 if fails > 0 else 0)
