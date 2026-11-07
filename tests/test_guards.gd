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
	check("a seed guards nothing around it", guards_square(farm._ward_protects, thorn, -1))
	farm.crops[thorn].set_days_grown(1)
	farm._refresh_crop_needs()
	check("a dry ward guards one tile around", guards_square(farm._ward_protects, thorn, ward.ward_dry_radius))
	await stand(thorn + Vector2i.LEFT)
	check("facing a ward shows no square", not highlight._filled)
	check("a dry sprout glows a little", farm.crops[thorn]._glow != null and farm.crops[thorn]._glow.visible)
	var small_light: float = farm.crops[thorn]._glow.texture_scale
	farm.water(thorn)
	farm._refresh_crop_needs()
	check("water makes its light reach further", farm.crops[thorn]._glow.texture_scale > small_light)
	check("a watered ward guards a square", guards_square(farm._ward_protects, thorn, ward.ward_radius))
	check("the corner is safe", farm._ward_protects(thorn + Vector2i(ward.ward_radius, ward.ward_radius)))
	await wait(3)

	# Ripe, it needs no water, because the big button can only burst it now.
	var crop: Node = farm.crops[thorn]
	crop.set_days_grown(ward.days_to_grow)
	farm.till(thorn)
	farm._refresh_crop_needs()
	await wait(2)
	check("a ripe ward is dry here", not farm.is_watered(thorn))
	check("a ripe ward glows", crop._glow != null and crop._glow.visible and crop._motes.emitting)
	var first_energy: float = crop._glow.energy
	await wait(30)
	check("the glow breathes", crop._glow.energy != first_energy)
	check("the ripe art is in place", ward.ripe_animation != null and crop.sprite.texture == ward.ripe_animation and crop.sprite.hframes == ward.ripe_frames)
	var seen: Dictionary = {}
	for i in 90:
		await physics_frame
		seen[crop.sprite.frame] = true
	check("and it plays every frame", seen.size() == ward.ripe_frames)
	crop.blighted = true
	check("blight puts the glow out", not crop._glow.visible)
	check("and stops the animation", crop.sprite.texture == ward.stages_texture and crop.sprite.frame == 3)
	crop.blighted = false
	check("it comes back", crop.sprite.texture == ward.ripe_animation)
	check("other crops stay calm", inv.CROPS[0].ripe_glow.a == 0.0)
	check("Action never bursts it", farm.smart_action(thorn) == farm.Action.NONE)
	check("Heal does", farm.smart_heal(thorn) == farm.Heal.BURST)
	check("it still guards without water", guards_square(farm._ward_protects, thorn, ward.ward_ripe_radius))
	farm.water(thorn)
	check("water doesn't change a ripe ward", guards_square(farm._ward_protects, thorn, ward.ward_ripe_radius))
	farm.till(thorn)

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
	check("facing a lantern shows no square", not highlight._filled)

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

	# Facing a ripe ward, the big button leaves it alone and the bottle bursts it.
	await stand(thorn + Vector2i.LEFT)
	farm.run_action()
	check("Action leaves a ripe ward alone", farm.crops.has(thorn))
	var water_before: int = inv.holy_water
	farm.run_heal()
	check("Heal bursts it", not farm.crops.has(thorn) and inv.holy_water == water_before)

	# Lanterns stay apart.
	player.tool = 5
	inv.add_building(lantern, 2)
	await stand(post + Vector2i(lantern.min_spacing - 2, 0))
	check("placing a lantern shows its square", highlight._filled and is_equal_approx(highlight._cell_rect.size.x, (lantern.guard_radius * 2 + 1) * tile))
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
