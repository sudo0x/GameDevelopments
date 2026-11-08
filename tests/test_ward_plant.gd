extends SceneTree
## Food crops can't protect themselves: the curse blights them. A watered wardthorn is poison to
## the curse and guards the land around it, and when ripe it bursts to heal cursed land.
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
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	inv.holy_water = 10
	progress.day = 5
	var ward: Variant = load("res://data/crops/wardthorn.tres")
	inv.seeds[&"wardthorn"] = 5
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	var farm: Node = main.get_node("Farm")
	var g: TileMapLayer = farm.ground
	var healing: Node = farm.healing
	main.get_node("World/Player")._safe_left = 9999.0
	var notices: Array = []
	gs.notice.connect(func(text: String) -> void: notices.append(text))
	var radish: Variant = inv.CROPS[0]
	check("the shop sells it", inv.CROPS.has(ward) and ward.seed_price > radish.seed_price)

	# A food crop on a marked tile is blighted, but the land stays clean.
	healing.cleanse(Vector2i(44, 3))
	var cell := Vector2i(43, 2)
	farm.till(cell)
	farm.plant(cell, radish)
	check("a food crop doesn't stop the curse", farm._can_curse_take(cell))
	healing.marked.assign([cell])
	check("a marked crop warns the player", farm.curse_status(cell).contains("blight"))
	progress.end_day()
	var crop: Node = farm.crops[cell]
	check("the crop is blighted", crop.blighted)
	check("the morning says so", notices.has("The curse blighted 1 crop."))
	check("its land stays clean", g.get_cell_source_id(cell) == GRASS)
	check("a blighted crop isn't marked again", not farm._can_curse_take(cell))
	var days: int = crop.days_grown
	farm.water(cell)
	progress.end_day()
	check("a blighted crop stops growing", crop.days_grown == days)
	check("it can be harvested at once", farm.can_use(3, cell))
	check("it explains itself", farm.crop_status(cell).contains("Blighted"))

	# Harvesting gives a little money and a curse shard, never a crop to sell.
	var shard: Variant = inv.MATERIALS.filter(func(m: Resource) -> bool: return m.id == &"curse_shard")[0]
	var money: int = inv.money
	farm.harvest(cell)
	check("a shard", inv.material_count(shard) == 1)
	check("a little money", inv.money == money + gs.BALANCE.blighted_crop_money)
	check("no crop to ship", inv.harvest_count(radish) == 0)
	check("the crop is gone", not farm.crops.has(cell))
	check("bare soil is open to the curse again", farm._can_curse_take(cell))

	# A blighted crop survives a restart through the farm's state.
	var keep := Vector2i(44, 2)
	farm.till(keep)
	farm.plant(keep, radish)
	farm.crops[keep].blighted = true
	var saved: Array = farm._to_state()["crops"]
	check("blight is saved", saved.any(func(c: Dictionary) -> bool: return c["cell"] == keep and c["blighted"]))

	# A wardthorn guards the land around it while it's watered.
	healing.cleanse(Vector2i(50, 3))
	var thorn := Vector2i(50, 4)
	var near := thorn + Vector2i(3, 0)
	var far := thorn + Vector2i(4, 0)
	farm.till(thorn)
	farm.plant(thorn, ward)
	check("a seed guards nothing around it", farm._can_curse_take(thorn + Vector2i(1, 0)))
	farm.water(thorn)
	check("even watered", farm._can_curse_take(thorn + Vector2i(1, 0)))
	check("its own tile is still safe", not farm._can_curse_take(thorn))
	farm.till(thorn)
	farm.crops[thorn].set_days_grown(1)
	check("a dry wardthorn only guards close by", farm._can_curse_take(near) and not farm._can_curse_take(thorn + Vector2i(1, 0)))
	farm.water(thorn)
	check("watered, it guards 3 tiles away", not farm._can_curse_take(near))
	check("4 tiles away isn't guarded", farm._can_curse_take(far))
	check("it can't be blighted", not farm._can_curse_take(thorn))

	# The night's check comes before the soil dries, so today's water counts.
	var guarded := Vector2i(51, 3)
	check("the guarded tile was healed", healing.cleansed.has(guarded))
	healing.marked.assign([guarded])
	progress.end_day()
	check("the guarded tile stays clean", g.get_cell_source_id(guarded) == GRASS)

	# Ripe, it keeps guarding until the player bursts it.
	for i in ward.days_to_grow:
		farm.water(thorn)
		progress.end_day()
	var plant: Node = farm.crops[thorn]
	check("it ripens", plant.is_ripe())
	farm.water(thorn)
	check("ripe, it still guards", not farm._can_curse_take(thorn + Vector2i(2, 0)))
	check("it says it can burst", farm.crop_status(thorn).contains("burst"))
	var healed: int = healing.cleansed.size()
	var holy: int = inv.holy_water
	farm.harvest(thorn)
	check("the burst heals cursed land", healing.cleansed.size() > healed)
	check("it costs no holy water", inv.holy_water == holy)
	check("the plant is spent", not farm.crops.has(thorn))
	check("no crop to ship", inv.harvest_count(ward) == 0)

	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
