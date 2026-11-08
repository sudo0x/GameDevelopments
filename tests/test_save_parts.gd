extends SceneTree
## The save file is written by three parts (SaveGame, Progress, Inventory). This guards what
## must stay true between them: the same keys as always, nothing lost, nothing left over.
const KEYS: Array[String] = [
	"version", "day", "guide_done", "book_pages", "money", "seeds", "harvest", "materials", "buildings",
	"holy_water", "strong_holy_water", "purifying_hoe", "sword", "bow", "arrows", "bag", "bag_slots", "farm_jobs", "build_tool", "plant_set", "combat_set", "combat_slot_2", "combat_slot_3", "build_set", "starter_kit", "farm",
]

var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var saves: Node = root.get_node("SaveGame")
	var radish: CropData = inv.CROPS[0]
	var wood: MaterialData = inv.MATERIALS[0]
	var fence: BuildingData = inv.building_by_id(&"fence")

	progress.day = 7
	progress.guide_done.assign(["till", "plant"])
	progress.book_pages = 6
	inv.money = 321
	inv.seeds[radish.id] = 4
	inv.harvest[radish.id] = 2
	inv.materials[wood.id] = 9
	inv.buildings[fence.id] = 3
	inv.holy_water = 6
	inv.strong_holy_water = 2
	inv.has_purifying_hoe = true
	inv.has_sword = true
	saves.farm_state = {"cleansed": [Vector2i(1, 2)]}
	saves.save_game()

	var file := ConfigFile.new()
	check("the save can be read", file.load(saves.SAVE_PATH) == OK)
	check("same keys, same order", Array(file.get_section_keys("game")) == Array(KEYS))
	check("same version", file.get_value("game", "version") == 1)

	saves._reset()
	check("reset: day", progress.day == 1 and progress.guide_done.is_empty())
	check("reset: book", progress.book_pages == 4)
	check("reset: money", inv.money == 0)
	check("reset: seeds", inv.seeds == inv.START_SEEDS)
	check("reset: bag", inv.harvest.is_empty() and inv.materials.is_empty() and inv.buildings.is_empty())
	check("reset: holy water", inv.holy_water == inv.BALANCE.start_holy_water and inv.strong_holy_water == 0)
	check("reset: upgrades", not inv.has_purifying_hoe and not inv.has_sword and inv.hoe_uses_left == 0)
	check("reset: farm", saves.farm_state.is_empty())

	saves.load_game()
	check("load: day", progress.day == 7 and progress.guide_done.size() == 2 and progress.guide_done.has("plant"))
	check("load: book", progress.book_pages == 6)
	check("load: money", inv.money == 321)
	check("load: bag", inv.seed_count(radish) == 4 and inv.harvest_count(radish) == 2 \
			and inv.material_count(wood) == 9 and inv.building_count(fence) == 3)
	check("load: holy water", inv.holy_water == 6 and inv.strong_holy_water == 2)
	check("load: upgrades", inv.has_purifying_hoe and inv.has_sword)
	check("load: the hoe is ready", inv.hoe_uses_left == inv.BALANCE.hoe_daily_uses)
	check("load: farm", saves.farm_state.has("cleansed"))

	# A day passing crosses all three parts, in this order.
	var order: Array[String] = []
	var on_end := func() -> void: order.append("end, money %d" % inv.money)
	var on_start := func() -> void: order.append("start, day %d" % progress.day)
	progress.day_ended.connect(on_end)
	progress.day_started.connect(on_start)
	inv.shipped[radish.id] = 1
	inv.holy_water_sold_today = 2
	inv.hoe_uses_left = 0
	progress.hearts = 1
	progress.end_day()
	check("paid before the day ends", order[0] == "end, money %d" % (321 + radish.sell_price))
	check("the day turns before morning", order[1] == "start, day 8")
	check("morning refills", inv.holy_water_sold_today == 0 and progress.hearts == inv.BALANCE.max_hearts \
			and inv.hoe_uses_left == inv.BALANCE.hoe_daily_uses)
	file.load(saves.SAVE_PATH)
	check("the morning was saved", file.get_value("game", "day") == 8)

	# Fainting takes money from one part and tells the other.
	var lost := [-1]
	progress.fainted.connect(func(amount: int) -> void: lost[0] = amount)
	var before: int = inv.money
	progress.take_damage(progress.hearts)
	var fee: int = before * inv.BALANCE.faint_money_percent / 100
	check("fainting costs the fee", lost[0] == fee and inv.money == before - fee)

	saves.start_new_game()
	check("new game: no save", not saves.has_save())
	check("new game: story", progress.show_story)

	print("ALL PASS" if fails == 0 else "%d FAILED" % fails)
	quit(fails)
