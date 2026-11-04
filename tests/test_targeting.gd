extends SceneTree
## Aim assist: the tile ahead first; if the tool can't use it, a tile beside it (nearer side
## first); the Hoe and Build tools always stay exact.
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
	for i in 3:
		await physics_frame
	var farm: Node = main.get_node("Farm")
	var player: Node = main.get_node("World/Player")
	var g: TileMapLayer = farm.ground
	var stand := func(cell: Vector2i, facing: int, tool: int, nudge := Vector2.ZERO) -> Vector2i:
		player.global_position = g.to_global(g.map_to_local(cell)) + Vector2(0, 4) + nudge
		player.facing = facing
		player.tool = tool
		return farm.smart_target_for(player)

	# A rock or tree on clean land, with clean grass to its left.
	var spot := Vector2i(-1, -1)
	for cell: Vector2i in farm.gathering.spots:
		var free := [cell + Vector2i(-1, 0), cell + Vector2i(-1, -1), cell + Vector2i(-2, -1), cell + Vector2i(0, -1)]
		if farm.gathering.can_hit(cell) and free.all(func(c: Vector2i) -> bool: return farm.is_farmable(c)):
			spot = cell
			break
	check("found a rock or tree to aim at " + str(spot), spot != Vector2i(-1, -1))

	# Facing right, one row above it: the tile ahead is empty grass, the rock is beside it.
	var hand := 3  # Player.Tool.HAND
	var right := 3  # Player.Facing.RIGHT
	check("the tile ahead has nothing to gather", not farm.gathering.can_hit(spot + Vector2i(0, -1)))
	check("the Hand finds the rock beside it", stand.call(spot + Vector2i(-1, -1), right, hand) == spot)
	check("straight on, the tile ahead wins", stand.call(spot + Vector2i(-1, 0), right, hand) == spot)

	# The Hoe stays exact: facing the rock, it doesn't wander to the grass beside it.
	var hoe := 0  # Player.Tool.HOE
	check("the Hoe never guesses", stand.call(spot + Vector2i(-1, 0), right, hoe) == spot)
	check("nothing usable anywhere: the tile ahead", stand.call(Vector2i(18, 12), 0, 2) == Vector2i(18, 13))

	# Watering: two dry soil tiles beside an empty tile ahead; the nearer side wins.
	var c := Vector2i(18, 12)
	var above := c + Vector2i(1, -1)
	var below := c + Vector2i(1, 1)
	farm.till(above)
	farm.till(below)
	var can := 1  # Player.Tool.WATERING_CAN
	check("leaning down picks the lower tile", stand.call(c, right, can, Vector2(0, 6)) == below)
	check("leaning up picks the upper tile", stand.call(c, right, can, Vector2(0, -8)) == above)
	farm.water(above)
	check("already watered is skipped", stand.call(c, right, can, Vector2(0, -8)) == below)

	# Sticky facing: a diagonal keeps a facing that still points the way you're walking.
	var down := 0  # Player.Facing.DOWN
	var left := 2  # Player.Facing.LEFT
	var up := 1  # Player.Facing.UP
	player.facing = down
	check("facing down, walking down-left: stays down", player._facing_for(Vector2(-1, 1)) == down)
	check("facing down, walking left: turns left", player._facing_for(Vector2.LEFT) == left)
	check("facing down, walking up-left: turns, side pose wins", player._facing_for(Vector2(-1, -1)) == left)
	player.facing = left
	check("facing left, walking down-left: stays left", player._facing_for(Vector2(-1, 1)) == left)
	check("facing left, walking up: turns up", player._facing_for(Vector2.UP) == up)
	check("a joystick slightly off down stays down from down", (func() -> bool:
		player.facing = down
		return player._facing_for(Vector2(0.6, 0.8)) == down).call())

	# The game uses it: the cursor and the action follow the assisted tile.
	stand.call(spot + Vector2i(-1, -1), right, hand)
	await physics_frame
	await physics_frame
	check("the cursor moves to the rock", farm.target_cell == spot and farm.highlight._valid)
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
