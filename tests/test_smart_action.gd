extends SceneTree
## Farm.smart_action(): one section per row of the chart in docs/23_..., then the order
## between the rows, then what must never happen by accident.
const NONE := 0
const SWING := 1
const INTERACT := 2
const HARVEST := 3
const WATER := 4
const PLANT := 5
const GATHER := 6
const TILL := 7

var fails := 0
var farm: Node
var player: Node
var main: Node


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


## Stands on an interact area, so it's in the player's reach.
func stand_on(area: Node2D) -> void:
	player.global_position = area.global_position + Vector2(0, 5)
	await wait(3)


func stand_clear() -> void:
	var g: TileMapLayer = farm.ground
	player.global_position = g.to_global(g.map_to_local(Vector2i(20, 12)))
	await wait(3)


## The action's tool must really work there, or the button would promise something false.
func tool_works(action: int, cell: Vector2i) -> bool:
	return farm.can_use(farm.ACTION_TOOLS[action], cell)


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var gs: Node = root.get_node("GameState")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	farm = main.get_node("Farm")
	player = main.get_node("World/Player")
	player._safe_left = 999.0
	await stand_clear()

	var box: Node2D = main.get_node("World/ShippingBox/Interact")
	var stall: Node2D = main.get_node("World/ShopStall/Interact")
	var bench: Node2D = main.get_node("World/Workbench/Interact")
	var door: Node2D = main.get_node("World/House/Door")
	var shrine: Node2D = main.get_node("World/Shrine")
	var radish: CropData = inv.CROPS[0]

	# Clean grass: till.
	var cell := Vector2i(24, 14)
	check("the test tile is clean grass", farm.is_farmable(cell))
	check("clean grass tills", farm.smart_action(cell) == TILL)
	check("the hoe works there", tool_works(TILL, cell))

	# Nothing to do.
	var cursed := Vector2i(60, 3)
	check("the test tile is cursed", farm.ground.get_cell_source_id(cursed) == 1)
	check("cursed land does nothing", farm.smart_action(cursed) == NONE)

	# Empty soil: plant the selected seed.
	farm.till(cell)
	check("empty soil plants", farm.smart_action(cell) == PLANT)
	check("the seeds work there", tool_works(PLANT, cell))
	farm.water(cell)
	check("watered empty soil plants too", farm.smart_action(cell) == PLANT)
	var kept: int = inv.seeds[radish.id]
	inv.seeds[radish.id] = 0
	check("no seeds, nothing to do", farm.smart_action(cell) == NONE)
	inv.seeds[radish.id] = kept
	farm.till(cell)  # Dry again.

	# A dry crop: water.
	farm.plant(cell, radish)
	check("a dry crop waters", farm.smart_action(cell) == WATER)
	check("the can works there", tool_works(WATER, cell))
	farm.water(cell)
	check("a watered crop needs nothing", farm.smart_action(cell) == NONE)
	farm.till(cell)

	# Ripe or blighted: harvest, even when dry.
	var crop: Node = farm.crops[cell]
	crop.blighted = true
	check("a blighted crop harvests", farm.smart_action(cell) == HARVEST)
	check("the hand works there", tool_works(HARVEST, cell))
	crop.blighted = false
	crop.set_days_grown(radish.days_to_grow)
	check("a ripe crop harvests, not waters", farm.smart_action(cell) == HARVEST)
	farm.water(cell)
	check("a ripe watered crop harvests", farm.smart_action(cell) == HARVEST)

	# Tree or rock: gather, and nothing once it's gone.
	var spot := Vector2i(-1, -1)
	for c: Vector2i in farm.gathering.spots:
		if farm.gathering.can_hit(c) and farm.gathering.spots[c].data.remains_solid:
			spot = c
			break
	check("found a tree with a solid stump", spot != Vector2i(-1, -1))
	check("a tree gathers", farm.smart_action(spot) == GATHER)
	check("the hand works on it", tool_works(GATHER, spot))
	farm.gathering.spots[spot].set_gathered(5)
	await wait(2)
	check("a stump does nothing", farm.smart_action(spot) == NONE)

	# Door, shop, box, bench and shrine.
	var free_cell := Vector2i(24, 16)
	inv.harvest[radish.id] = 1
	for area: Node2D in [door, stall, box, bench, shrine]:
		await stand_on(area)
		check(area.get_parent().name + "/" + area.name + " is used", farm.smart_action(free_cell) == INTERACT)

	# Objects with nothing to do don't get in the way of the tile.
	inv.harvest.clear()
	await stand_on(box)
	check("an empty box leaves the tile free", farm.smart_action(free_cell) == TILL)
	check("F still reaches the empty box", player.interact_target() == box)
	inv.harvest[radish.id] = 0
	check("a crop count of 0 is still empty", farm.smart_action(free_cell) == TILL)
	inv.harvest.clear()
	shrine.restored = true
	await stand_on(shrine)
	check("a restored shrine leaves the tile free", farm.smart_action(free_cell) == TILL)
	shrine.restored = false

	# Order: objects come before the tile.
	inv.harvest[radish.id] = 1
	await stand_on(box)
	check("the box beats a ripe crop", farm.smart_action(cell) == INTERACT)

	# Order: a close creature comes first, but only with a sword.
	var data: CreatureData = farm.spawner.CREATURES[0]
	farm.spawner._spawn(player.global_position + Vector2(20, 0), data)
	await wait(1)
	check("no sword, so the box still wins", farm.smart_action(cell) == INTERACT)
	inv.has_sword = true
	check("the sword beats the box", farm.smart_action(cell) == SWING)
	var creature: Node2D = farm.spawner.creatures.back()
	creature.global_position = player.global_position + Vector2(gs.BALANCE.action_swing_distance + 40.0, 0)
	check("a far creature doesn't swing", farm.smart_action(cell) == INTERACT)
	farm.spawner.clear()
	await wait(2)
	check("a defeated creature doesn't swing", farm.smart_action(cell) == INTERACT)
	inv.harvest.clear()
	await stand_clear()
	check("with no creature the tile decides", farm.smart_action(cell) == HARVEST)

	# Never by accident.
	inv.has_purifying_hoe = true
	inv.hoe_uses_left = 3
	check("holy water is never Action's", farm.smart_action(cursed) == NONE)
	var fence: BuildingData = inv.building_by_id(&"fence")
	for building: BuildingData in [fence, inv.building_by_id(&"lantern_post"), inv.building_by_id(&"well")]:
		var at := Vector2i(26, 14)
		inv.add_building(building)
		farm.builder.place(at, building)
		await wait(2)
		check(building.id + " is never picked up or tilled", farm.smart_action(at) == NONE)
		farm.builder.pick_up(at)
		await wait(2)
	farm.harvest(cell)
	check("emptied soil plants, never hoes back", farm.smart_action(cell) == PLANT)

	# Asking changes nothing.
	var tool_before: int = player.tool
	var money_before: int = inv.money
	var seeds_before: int = inv.seed_count(radish)
	farm.smart_action(free_cell)
	check("asking changes nothing", player.tool == tool_before and inv.money == money_before \
			and inv.seed_count(radish) == seeds_before and not farm.is_tilled(free_cell))

	print("ALL PASS" if fails == 0 else "%d FAILED" % fails)
	quit(fails)
