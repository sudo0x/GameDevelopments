extends SceneTree
## The bow (storage controls, docs/28_...): crafted once, it goes first in the combat set; it
## needs arrows, and the sword takes over when they run out. A shot draws the bow, spends one
## arrow, and the arrow hits the first thing in its way. Runs without --classic-controls.
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
	var bow_recipe: RecipeData = inv.RECIPES.filter(func(r: RecipeData) -> bool: return r.display_name == "Bow")[0]
	var arrow_recipe: RecipeData = inv.RECIPES.filter(func(r: RecipeData) -> bool: return r.display_name == "Arrows")[0]

	# Crafting.
	inv.materials[&"wood"] = 20
	inv.materials[&"stone"] = 5
	inv.materials[&"curse_shard"] = 2
	check("the bow can be crafted", inv.craft(bow_recipe) and inv.has_bow)
	check("only once", not inv.can_craft(bow_recipe))
	check("it goes on the first empty combat button", inv.combat_item(0) == &"sword" and inv.combat_item(1) == &"bow")
	inv.pick_combat(1)
	check("with no arrows the bow can't be used", farm.weapon() == &"")
	check("arrows come in tens", inv.craft(arrow_recipe) and inv.carried(&"arrows") == 10)
	check("with arrows the bow is used", farm.weapon() == &"bow")
	inv.toggle_in_combat_slot(&"sword", 1)
	check("a button holds more than one weapon", inv.combat_slot(1) == [&"bow", &"sword"])
	inv.tap_combat(1)
	check("tapping the picked button goes to its next weapon", farm.weapon() == &"sword")
	inv.tap_combat(1)
	check("and round again", farm.weapon() == &"bow")
	inv.toggle_in_combat_slot(&"sword", 0)
	check("adding to another button moves it there", inv.combat_slot(0) == [&"sword"] and inv.combat_slot(1) == [&"bow"])
	inv.tap_combat(0)
	check("tapping another button picks it", inv.combat_pick == 0 and farm.weapon() == &"sword")
	inv.toggle_in_combat_slot(&"sword", 0)
	inv.toggle_in_combat_slot(&"bow", 0)
	inv.toggle_in_combat_slot(&"sword", 0)
	check("up to three, in the order added", inv.combat_slot(0) == [&"bow", &"sword"])
	inv.toggle_in_combat_slot(&"bow", 0)
	inv.toggle_in_combat_slot(&"bow", 1)
	inv.pick_combat(1)
	check("arrows can't go in a set", not inv.can_set(&"arrows"))

	# Shooting.
	var g: TileMapLayer = farm.ground
	player.global_position = g.to_global(g.map_to_local(Vector2i(22, 18))) + Vector2(0, 4)
	player.facing = RIGHT
	player.set_mode(1)
	await wait(3)
	check("Combat mode shoots", farm.smart_action(farm.target_cell_for(player)) == farm.Action.SHOOT)
	check("the hand line counts arrows", hud.tool_label.text == "Combat 2: Bow, 10 arrows")
	var dummy := make_dummy()
	main.get_node("World").add_child(dummy)
	dummy.global_position = player.bow.global_position + Vector2(80, 0)
	await wait(2)
	await press("action")
	check("a shot spends an arrow", inv.carried(&"arrows") == 9)
	check("the bow shows while drawn", player.bow.sprite.visible)
	await wait(4)
	check("the bow draws through its frames", player.bow.sprite.frame > 0 or not player.bow.sprite.visible)
	await wait(40)
	check("the arrow hits", dummy.hits == 1)
	check("and is gone", main.get_node("World").get_children().filter(func(n: Node) -> bool: return n is Arrow).is_empty())
	await press("action")
	await press("action")
	check("no second shot mid-draw", inv.carried(&"arrows") == 8)

	# An arrow that hits nothing falls after its range.
	dummy.queue_free()
	await wait(30)
	await press("action")
	await wait(2)
	var flying: Array = main.get_node("World").get_children().filter(func(n: Node) -> bool: return n is Arrow)
	check("a shot with nothing ahead flies", flying.size() == 1)
	await wait(60)
	check("then falls", not is_instance_valid(flying[0]))

	# Out of arrows: the bow does nothing until the sword's button is picked.
	inv.arrows = 0
	inv.bag.erase(&"arrows")
	await wait(2)
	check("no arrows: the bow does nothing", farm.weapon() == &"" and farm.smart_action(farm.target_cell_for(player)) == farm.Action.NONE)
	inv.pick_combat(0)
	check("picking the sword's button swings", farm.smart_action(farm.target_cell_for(player)) == farm.Action.SWING)

	# Saving.
	var file := ConfigFile.new()
	inv.arrows = 7
	inv.save_to(file)
	file.parse(file.encode_to_text())
	inv.reset()
	inv.load_from(file)
	check("the bow and arrows are saved", inv.has_bow and inv.arrows == 7)

	print("Done: %d failed" % fails)
	quit(1 if fails > 0 else 0)
