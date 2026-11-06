extends SceneTree
## From day 4, the curse takes a few empty healed tiles along its edge back each night.
const GRASS := 0
const CURSED := 1
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	gs.holy_water = 20
	gs.strong_holy_water = 5
	gs.buildings[&"lantern_post"] = 1
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var healing: Node = farm.healing
	var hud: Node = main.get_node("HUD")
	var player: Node2D = main.get_node("World/Player")
	player._safe_left = 9999.0
	var notices: Array = []
	gs.notice.connect(func(text: String) -> void: notices.append(text))
	check("three tiles a night to start", gs.BALANCE.curse_return_per_night == 3)
	check("starts on day 4", gs.BALANCE.curse_return_first_day == 4)

	# A 5×5 patch: the middle tile has no curse beside it.
	var middle := Vector2i(44, 3)
	healing.cleanse(middle, true)
	var healed: int = healing.cleansed.size()
	check("the patch healed", healed == 25)
	var shore_and_healed: int = g.get_used_cells_by_id(GRASS).size()

	gs.end_day()
	gs.end_day()
	gs.end_day()
	check("the first days stay calm", gs.day == 4 and healing.cleansed.size() == healed)

	check("the morning marks tonight's tiles", healing.marked.size() == 3 and healing._marks._rects.size() == 3)
	check("marked tiles touch the curse", healing.marked.all(func(c: Vector2i) -> bool: return healing._touches_curse(c)))
	check("the morning says so", notices.has("The curse has marked 3 tiles for tonight."))
	check("a marked tile explains itself", farm.curse_status(healing.marked[0]).contains("tonight"))
	check("other tiles say nothing", farm.curse_status(middle).is_empty())
	var tonight: Array = healing.marked.duplicate()
	var before: Array = healing.cleansed.duplicate()
	var percent: float = gs.healed_percent
	gs.end_day()
	var lost: Array = before.filter(func(c: Vector2i) -> bool: return not healing.cleansed.has(c))
	check("three tiles returned", lost.size() == 3 and healing.cleansed.size() == healed - 3)
	check("exactly the marked tiles returned", tonight.all(func(c: Vector2i) -> bool: return lost.has(c)))
	check("the morning after says so", notices.has("The curse took back 3 tiles overnight."))
	check("they are cursed again", lost.all(func(c: Vector2i) -> bool: return g.get_cell_source_id(c) == CURSED))
	check("texture piece lines up", g.get_cell_atlas_coords(lost[0]) == farm.texture_coords(lost[0]))
	check("only healed land was lost", g.get_used_cells_by_id(GRASS).size() == shore_and_healed - 3)
	check("the score went down", gs.healed_percent < percent)
	check("the morning save knows", gs.farm_state["cleansed"].size() == healed - 3)
	check("the middle is safe for now", healing.cleansed.has(middle))
	await wait(2)
	check("returned land blocks farming", not farm.is_farmable(lost[0]))
	check("returned land can be healed", healing.is_cleansable(lost[0]))

	# Using a marked tile saves it, and its mark goes at once.
	var save_me: Vector2i = healing.marked[0]
	var lose_me: Array = healing.marked.slice(1)
	farm.target_cell = save_me
	await wait(1)
	farm.target_cell = save_me
	farm._on_tool_used(0)
	check("tilling a marked tile works", farm.is_tilled(save_me))
	check("its mark goes", healing._marks._rects.size() == 2)
	check("it stops warning", farm.curse_status(save_me).is_empty())
	gs.end_day()
	check("the saved tile stays", healing.cleansed.has(save_me) and g.get_cell_source_id(save_me) == GRASS)
	check("the others go", lose_me.all(func(c: Vector2i) -> bool: return g.get_cell_source_id(c) == CURSED))
	farm.untill(save_me)

	# Healing around a marked tile saves it too.
	var ringed: Vector2i = healing.marked[0]
	var neighbors: Array = g.get_surrounding_cells(ringed).filter(func(c: Vector2i) -> bool: return g.get_cell_source_id(c) == CURSED)
	for cell: Vector2i in neighbors:
		var one: Array[Vector2i] = [cell]
		healing._cleanse_cells(one, cell)
	check("land no longer beside the curse is safe", not healing.is_at_risk(ringed, farm._can_curse_take))

	# The same night always plays out the same way.
	var all_free := func(_c: Vector2i) -> bool: return true
	var picked: Array = []
	for run in 2:
		gs.day = 9
		var taken: Array = []
		var keep: Array = healing.cleansed.duplicate()
		healing.mark_tonight(all_free)
		healing.curse_returns(all_free)
		taken = keep.filter(func(c: Vector2i) -> bool: return not healing.cleansed.has(c))
		picked.append(taken)
		for cell: Vector2i in taken:
			healing._heal(cell)
		healing.cleansed.assign(keep)
	check("seeded by the day", picked[0] == picked[1] and picked[0].size() == 3)
	healing.curse_edges.refresh(g)

	# Nothing the player made is taken.
	var empty: Vector2i = healing.cleansed[0]
	check("empty land can be taken", farm._can_curse_take(empty))
	farm.till(empty)
	check("soil is safe", not farm._can_curse_take(empty))
	farm.untill(empty)
	farm.builder.place(empty, gs.BUILDINGS[0])
	check("a building is safe", not farm._can_curse_take(empty))
	var spot: Vector2i = farm.gathering.spots.keys()[0]
	check("a tree or rock is safe", not farm._can_curse_take(spot))

	# A tile that can't be taken stays, even at the curse's edge.
	var kept: int = healing.cleansed.size()
	gs.day = 10
	healing.mark_tonight(all_free)
	check("nothing free, nothing lost", healing.curse_returns(func(_c: Vector2i) -> bool: return false) == 0)
	check("nothing free, nothing taken", healing.cleansed.size() == kept)

	# A find pays once, however many times its land is healed.
	var find := Vector2i(53, 11)
	var money: int = gs.money
	healing.cleanse(Vector2i(54, 12))
	check("the find paid", gs.money == money + 80)
	check("the find is remembered", healing.dug_finds.has(find) and not healing.finds.has(find))
	gs.day = 11
	var only_find := func(c: Vector2i) -> bool: return c == find
	healing.mark_tonight(only_find)
	healing.curse_returns(only_find)
	check("the find's land returned", g.get_cell_source_id(find) == CURSED)
	check("no new glimmer", not healing._glimmers.has(find))
	healing.cleanse(find)
	check("healed again, no second payment", g.get_cell_source_id(find) == GRASS and gs.money == money + 80)

	# Fainting at the curse's edge still ends at home, never stuck on returned land.
	player.global_position = g.to_global(g.map_to_local(healing.cleansed[0]))
	hud._faint(0)
	await wait(120)
	var feet: Vector2i = g.local_to_map(g.to_local(player.global_position))
	check("wakes on clean ground", g.get_cell_source_id(feet) == GRASS)

	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
