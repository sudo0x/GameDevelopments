extends SceneTree
## The item menus with storage controls (docs/28_...): workbench, stall and storage share one
## layout of tabs, a tile grid and a details side with buttons. Runs without --classic-controls.

var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var gs: Node = root.get_node("GameState")
	root.get_node("SaveGame").start_new_game()
	root.get_node("Progress").show_story = false
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var hud: Node = main.get_node("HUD")

	# Workbench.
	var bench: Node = hud.get_node("WorkbenchMenu")
	gs.request_crafting()
	await process_frame
	check("the workbench opens the grid menu", bench.visible and not hud.get_node("CraftingMenu").visible)
	check("every recipe is a tile", bench.tiles_text.split(", ").size() == inv.RECIPES.size())
	check("the first tile is picked", bench.details_text.begins_with("Holy water"))
	bench._tab = "Build"
	bench._refresh()
	check("the Build tab shows only buildings", bench.tiles_text.split(", ").size() == 3 and bench.details_text.begins_with("Lantern post"))
	check("details list the needs", bench.details_text.contains("5 Wood (have 0)"))
	check("Make is off without materials", not bench.press_button("Make"))
	inv.materials[&"wood"] = 5
	inv.materials[&"stone"] = 3
	inv.materials[&"curse_shard"] = 2
	bench._refresh()
	check("Make works with them", bench.press_button("Make") and inv.building_count(inv.building_by_id(&"lantern_post")) == 2)
	check("each item has a description", bench.details_text.contains("Guards a 5x5 area"))
	bench.close()

	# Stall.
	var stall: Node = hud.get_node("StallMenu")
	inv.money = 100
	gs.request_shop()
	await process_frame
	check("the stall opens the grid menu", stall.visible and not hud.get_node("ShopMenu").visible)
	check("the money is in the title", stall._title.text.contains("Money: 100"))
	var radish_before: int = inv.total(&"seed_radish")
	check("Buy 1", stall.press_button("Buy 1 for 10") and inv.total(&"seed_radish") == radish_before + 1 and inv.money == 90)
	check("Buy 5", stall.press_button("Buy 5 for 50") and inv.total(&"seed_radish") == radish_before + 6 and inv.money == 40)
	stall.pick(&"seed_wardthorn")
	check("rare seeds say what's left today", stall.details_text.contains("Left today: 1"))
	check("and can't be bought five at once", not stall.details_text.contains("Buy 5"))
	stall.pick(&"holy_water")
	check("holy water is for sale", stall.details_text.contains("Price: 30") and stall.press_button("Buy 1 for 30"))
	stall.close()

	# Storage.
	var chest: Node = hud.get_node("StorageMenu")
	inv.put(&"seed_carrot")
	gs.request_storage()
	await process_frame
	chest.pick(&"seed_carrot")
	check("storage shows bag and chest", chest.details_text.contains("In bag: 0\nIn chest: 5"))
	check("Take 1", chest.press_button("Take 1") and inv.carried(&"seed_carrot") == 1)
	check("Take all", chest.press_button("Take all") and inv.carried(&"seed_carrot") == 5)
	check("Put all", chest.press_button("Put all") and inv.stored(&"seed_carrot") == 5)
	inv.materials[&"wood"] = 3
	inv.materials[&"curse_shard"] = 1
	chest._tab = "Materials"
	chest._refresh()
	check("the Materials tab shows only materials owned", chest.tiles_text == "mat_wood, mat_curse_shard")
	chest.get_node("CloseOverlay/CloseButton").pressed.emit()
	check("the X closes it", not chest.visible)

	# The bag: a Bag page of items, and a Modes page of what the big button does.
	var bag: Node = hud.get_node("SetsMenu")
	bag.open()
	await process_frame
	check("the bag opens on the Bag page", bag._page == "Bag" and bag._tab == "All" and not bag.tiles_text.contains("job_"))
	bag.show_page("Modes")
	check("Modes opens on the mode in use", bag._tab == "Farm mode" and bag.details_text.begins_with("Farm job: Till"))
	check("a job turns off from its details", bag.press_button("Turn off") and not inv.farm_jobs.has(&"till"))
	check("and on again", bag.press_button("Turn on") and inv.farm_jobs.has(&"till"))
	var harvest_at: int = Array(bag.tiles_text.split(", ")).find("job_harvest")
	bag._tiles[harvest_at].pressed.emit()
	check("one tap on a job tile flips it", not inv.farm_jobs.has(&"harvest") and bag.details_text.begins_with("Farm job: Harvest"))
	harvest_at = Array(bag.tiles_text.split(", ")).find("job_harvest")
	check("an off job is dark", bag._tiles[harvest_at].self_modulate == bag.OFF_TINT)
	bag._tiles[harvest_at].pressed.emit()
	check("and back", inv.farm_jobs.has(&"harvest"))
	check("the tab has headings", bag._list.get_child(0) is Label and bag._list.get_child(0).text.begins_with("Jobs"))
	inv.bag_slots = 20
	inv.take(&"seed_carrot")
	bag.pick(&"seed_carrot")
	check("a seed shows its place", bag.details_text.contains("Planting: 2nd"))
	check("Plant sooner moves it up", bag.press_button("Plant sooner") and inv.plant_set[0] == &"seed_carrot")
	check("first can't go sooner", not bag.press_button("Plant sooner"))
	check("Don't plant takes it out", bag.press_button("Don't plant") and not inv.plant_set.has(&"seed_carrot"))
	check("it shows under Not planting", bag.tiles_text.contains("seed_carrot"))
	var carrot_at: int = Array(bag.tiles_text.split(", ")).find("seed_carrot")
	bag._tiles[carrot_at].pressed.emit()
	check("one tap adds it back, last", inv.plant_set.back() == &"seed_carrot")
	bag._tab = "Combat mode"
	bag._refresh()
	check("combat shows a row per button", bag.tiles_text.contains("slot0_sword") and bag.tiles_text.contains("slot1_sword") and bag.tiles_text.contains("slot2_sword"))
	var slot_at: int = Array(bag.tiles_text.split(", ")).find("slot1_sword")
	bag._tiles[slot_at].pressed.emit()
	check("a tap puts a weapon on a separate combat button", inv.combat_slot(1) == [&"sword"] and bag.details_text.contains("[Take off]"))
	slot_at = Array(bag.tiles_text.split(", ")).find("slot2_sword")
	bag._tiles[slot_at].pressed.emit()
	check("and to the third button independently", inv.combat_slot(2) == [&"sword"])
	bag._tab = "Build mode"
	bag._refresh()
	var move_at: int = Array(bag.tiles_text.split(", ")).find("job_move")
	bag._tiles[move_at].pressed.emit()
	check("a tap picks the build tool", inv.build_tool == &"move" and bag.details_text.contains("[Use this off]"))
	inv.set_build_tool(&"place")
	bag.show_page("Bag")
	inv.add_material(inv.MATERIALS[0], 1)
	bag._tab = "Materials"
	bag.pick(&"mat_wood")
	check("materials say where they're used", bag.details_text.contains("Use it at the workbench"))
	bag.close()

	print("Done: %d failed" % fails)
	quit(1 if fails > 0 else 0)
