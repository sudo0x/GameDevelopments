extends SceneTree
## Ward plants and lanterns guard squares you can see, and lanterns stay spread out.
const RIGHT := 3

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


func stand(cell: Vector2i) -> void:
	var g: TileMapLayer = farm.ground
	player.global_position = g.to_global(g.map_to_local(cell)) + Vector2(0, 4)
	player.facing = RIGHT
	await wait(3)


## Every cell in the square is guarded, and nothing just outside it is.
func guards_square(guarded: Callable, center: Vector2i, radius: int) -> bool:
	for y in range(-radius - 1, radius + 2):
		for x in range(-radius - 1, radius + 2):
			var inside := maxi(absi(x), absi(y)) <= radius
			if guarded.call(center + Vector2i(x, y)) != inside:
				print("wrong at ", Vector2i(x, y))
				return false
	return true


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	farm = main.get_node("Farm")
	player = main.get_node("World/Player")
	player._safe_left = 999.0
	var ward: CropData = inv.crop_by_id(&"wardthorn")
	var lantern: BuildingData = inv.building_by_id(&"lantern_post")
	var highlight: Node2D = farm.highlight
	var tile := 32.0

	# The numbers the design depends on.
	check("wardthorn guards more than a lantern", ward.ward_radius > lantern.guard_radius)
	check("wardthorn is cheap", ward.seed_price <= 30)
	var recipe: RecipeData = inv.RECIPES[2]
	var shards := recipe.needs.filter(func(n: RecipeNeed) -> bool: return n.material == inv.CURSE_SHARD)
	check("lanterns need curse shards", recipe.building == lantern and shards.size() == 1 and shards[0].amount == 2)

	# A ward plant: a full square, corners too, only while watered.
	var thorn := Vector2i(22, 14)
	inv.seeds[ward.id] = 1
	farm.till(thorn)
	farm.plant(thorn, ward)
	check("a dry ward guards nothing", not farm._ward_protects(thorn + Vector2i.RIGHT))
	await stand(thorn + Vector2i.LEFT)
	check("facing a dry ward shows its area in red", highlight.visible and not highlight._valid)
	farm.water(thorn)
	check("a watered ward guards a square", guards_square(farm._ward_protects, thorn, ward.ward_radius))
	check("the corner is safe", farm._ward_protects(thorn + Vector2i(ward.ward_radius, ward.ward_radius)))
	await wait(3)
	var shown: Rect2 = highlight._cell_rect
	check("the cursor covers the guarded square", is_equal_approx(shown.size.x, (ward.ward_radius * 2 + 1) * tile) and highlight._valid and highlight._filled)

	# A lantern: a smaller square, for good.
	var post := Vector2i(26, 14)
	inv.add_building(lantern)
	player.tool = 5
	player.building_index = inv.BUILDINGS.find(lantern)
	await wait(2)
	farm.builder.place(post, lantern)
	player.tool = 0
	await wait(3)
	check("a lantern guards a square", guards_square(farm._lantern_protects, post, lantern.guard_radius))
	await stand(post + Vector2i.LEFT)
	check("facing a lantern shows its area", highlight.visible and farm.guard_radius_at(post) == lantern.guard_radius)

	# A burst heals the same square.
	var healing: Node = farm.healing
	var edge := Vector2i(-1, -1)
	for y in range(5, 22):
		for x in range(20, 45):
			var c := Vector2i(x, y)
			if edge == Vector2i(-1, -1) and farm.is_farmable(c) and healing.is_cleansable(c + Vector2i.RIGHT):
				edge = c
	var square: Array = healing.cleansable_square(edge, ward.burst_radius)
	check("the burst stays in its square", square.all(func(c: Vector2i) -> bool: return farm.tiles_apart(c, edge) <= ward.burst_radius))
	var healed: int = healing.burst(edge, ward.burst_radius)
	check("a burst heals the whole square", healed == square.size() and healed > 0)

	# Lanterns stay apart.
	player.tool = 5
	inv.add_building(lantern, 2)
	await stand(post + Vector2i(lantern.min_spacing - 2, 0))
	var near := post + Vector2i(lantern.min_spacing - 1, 0)
	check("the near tile is free", farm.can_build(near))
	check("too close can't be built", not farm.can_use(5, near))
	check("it says why", farm.spacing_status(near).contains("%d tiles apart" % lantern.min_spacing))
	var far := post + Vector2i(lantern.min_spacing, 0)
	check("far enough can", farm.can_build(far) and farm.can_use(5, far))
	check("other buildings don't care", farm.builder.has_room(near, inv.building_by_id(&"fence")))
	check("diagonals count", not farm.builder.has_room(post + Vector2i(lantern.min_spacing - 1, lantern.min_spacing - 1), lantern))

	# Moving keeps the rule, but doesn't count against itself.
	farm.builder.place(far, lantern)
	await wait(3)
	check("a lantern can't move next to another", not farm.can_move(far, near))
	check("it can shift a tile away", farm.can_move(far, far + Vector2i.RIGHT))
	player.tool = 0

	print("ALL PASS" if fails == 0 else "%d FAILED" % fails)
	quit(fails)
