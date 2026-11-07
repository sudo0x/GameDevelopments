extends SceneTree
## The phone's Seed popup and Heal button, and Build mode's picking up.
const SEED_AT := Vector2(526, 322)
const HEAL_AT := Vector2(596, 216)
const ACTION_AT := Vector2(596, 296)
const BAG_AT := Vector2(526, 262)
const RIGHT := 3

var fails := 0
var farm: Node
var player: Node


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func touch(at: Vector2, finger: int, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = finger
	e.position = root.get_final_transform() * at
	e.pressed = pressed
	Input.parse_input_event(e)
	Input.flush_buffered_events()


func tap(at: Vector2) -> void:
	touch(at, 1, true)
	await wait(2)
	touch(at, 1, false)
	await wait(2)


func stand(cell: Vector2i) -> void:
	var g: TileMapLayer = farm.ground
	player.global_position = g.to_global(g.map_to_local(cell)) + Vector2(0, 4)
	player.facing = RIGHT
	await wait(3)


func _initialize() -> void:
	_run()


func _run() -> void:
	var inv: Node = root.get_node("Inventory")
	var progress: Node = root.get_node("Progress")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await wait(3)
	farm = main.get_node("Farm")
	player = main.get_node("World/Player")
	player._safe_left = 999.0
	var hud: Node = main.get_node("HUD")
	var controls: Node = main.get_node("HUD/TouchControls")
	var pick: Control = main.get_node("HUD/PickMenu")
	controls.set_active(true)
	await wait(3)

	# The plan's 5 buttons.
	var showing: Array = []
	for action: String in controls._buttons:
		if controls._buttons[action].is_visible_in_tree():
			showing.append(action)
	showing.sort()
	check("the planned buttons show", showing == ["action", "heal", "inventory", "seed_menu", "ui_cancel"])
	var rects: Array[Rect2] = []
	for action: String in showing:
		var b: Node2D = controls._buttons[action]
		rects.append(Rect2(b.position, b.texture_normal.get_size() * b.scale))
	var clear := true
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			clear = clear and not rects[i].intersects(rects[j])
	check("no buttons overlap", clear)
	var action_rect: Node2D = controls._buttons["action"]
	var heal_rect: Node2D = controls._buttons["heal"]
	var gap: float = action_rect.position.y - (heal_rect.position.y + 42.0)
	check("Heal is kept apart from Action", gap >= 12.0)

	# Seed popup.
	var radish: CropData = inv.CROPS[0]
	var carrot: CropData = inv.CROPS[1]
	check("Seed shows the selected seed", controls._seed_icon.texture == radish.seed_icon)
	await tap(SEED_AT)
	check("Seed opens the popup", pick.visible and paused)
	check("it lists every seed", pick._rows.get_child_count() == inv.CROPS.size())
	check("it fits the screen", pick.get_global_rect().size.y <= 360.0 and pick.get_global_rect().position.y >= 0.0)
	check("it clears the buttons left showing", pick.get_global_rect().end.x <= 501.0)
	pick._rows.get_child(1).pressed.emit()
	check("picking closes it", not pick.visible and not paused)
	check("the seed changes", player.selected_seed() == carrot)
	await wait(2)
	check("the button follows", controls._seed_icon.texture == carrot.seed_icon)
	check("the text shows what's left", hud.tool_label.text == "%s seeds: %d" % [carrot.display_name, inv.seed_count(carrot)])
	var kept: int = inv.seeds[carrot.id]
	inv.seeds[carrot.id] = 0
	inv.inventory_changed.emit()
	await wait(2)
	check("no seeds left dims it", controls._buttons["seed_menu"].modulate.a < 1.0)
	await tap(SEED_AT)
	check("and it still opens", pick.visible)
	check("the empty seed is dimmed in the list", pick._rows.get_child(1).modulate.a < 1.0)
	await tap(ACTION_AT)
	check("! closes the popup", not pick.visible)
	await wait(2)
	inv.seeds[carrot.id] = kept
	inv.inventory_changed.emit()
	player.select_seed(0)

	# Beside the curse.
	var edge := Vector2i(-1, -1)
	for y in range(5, 22):
		for x in range(20, 45):
			var c := Vector2i(x, y)
			if edge == Vector2i(-1, -1) and farm.is_farmable(c) and farm.healing.is_cleansable(c + Vector2i.RIGHT):
				edge = c
	var cursed: Vector2i = edge + Vector2i.RIGHT
	await stand(edge)
	check("facing the curse lights Heal", controls._buttons["heal"].modulate == Color.WHITE)

	# Holy water.
	var water: int = inv.holy_water
	var cells: int = farm.healing.cleansed.size()
	await tap(HEAL_AT)
	check("Heal spends one holy water", inv.holy_water == water - 1)
	check("and heals a patch", farm.healing.cleansed.size() > cells + 1)
	check("the guide heard it", progress.guide_done.has("heal"))

	# Nothing to heal.
	await stand(Vector2i(22, 14))
	check("nothing to heal dims it", controls._buttons["heal"].modulate.a < 1.0)
	water = inv.holy_water
	await tap(HEAL_AT)
	check("a dim Heal spends nothing", inv.holy_water == water)

	# The hoe's free uses come first, on a cursed tile.
	var next_edge := Vector2i(-1, -1)
	for y in range(5, 22):
		for x in range(20, 45):
			var c := Vector2i(x, y)
			if next_edge == Vector2i(-1, -1) and farm.is_farmable(c) and farm.healing.is_cleansable(c + Vector2i.RIGHT):
				next_edge = c
	await stand(next_edge)
	inv.has_purifying_hoe = true
	inv.hoe_uses_left = 1
	water = inv.holy_water
	cells = farm.healing.cleansed.size()
	await wait(2)
	check("Heal picks the hoe first", farm.smart_heal(next_edge + Vector2i.RIGHT) == farm.Heal.PURIFY)
	await tap(HEAL_AT)
	check("the hoe heals one tile", farm.healing.cleansed.size() == cells + 1 and inv.hoe_uses_left == 0)
	check("holy water is kept", inv.holy_water == water)
	await wait(2)
	inv.has_purifying_hoe = false

	# Two kinds of water: the player chooses.
	var last_edge := Vector2i(-1, -1)
	for y in range(5, 22):
		for x in range(20, 45):
			var c := Vector2i(x, y)
			if last_edge == Vector2i(-1, -1) and farm.is_farmable(c) and farm.healing.is_cleansable(c + Vector2i.RIGHT):
				last_edge = c
	await stand(last_edge)
	inv.strong_holy_water = 2
	inv.holy_water = 2
	await wait(2)
	await tap(HEAL_AT)
	check("two kinds asks which", pick.visible and pick._rows.get_child_count() == 2)
	check("asking spends nothing yet", inv.holy_water == 2 and inv.strong_holy_water == 2)
	pick._rows.get_child(1).pressed.emit()
	await wait(2)
	check("strong was spent", inv.strong_holy_water == 1 and inv.holy_water == 2)
	await stand(Vector2i(22, 14))
	inv.holy_water = 0
	inv.strong_holy_water = 1
	var far_edge := Vector2i(-1, -1)
	for y in range(5, 22):
		for x in range(20, 45):
			var c := Vector2i(x, y)
			if far_edge == Vector2i(-1, -1) and farm.is_farmable(c) and farm.healing.is_cleansable(c + Vector2i.RIGHT):
				far_edge = c
	await stand(far_edge)
	await tap(HEAL_AT)
	check("one kind doesn't ask", not pick.visible and inv.strong_holy_water == 0)
	check("no water dims it", farm.smart_heal(far_edge + Vector2i.RIGHT) == farm.Heal.NONE)

	# Build mode: only what's owned is listed.
	var bag: Control = main.get_node("HUD/BagMenu")
	var fence: BuildingData = inv.building_by_id(&"fence")
	var well: BuildingData = inv.building_by_id(&"well")
	inv.buildings.clear()
	await tap(BAG_AT)
	bag.build_button.pressed.emit()
	await wait(2)
	check("owning nothing opens no list", not pick.visible and not paused and player.tool != 5)
	check("it says where to get things", hud.latest_notice().contains("workbench") or hud._waiting_notices.any(func(n: String) -> bool: return n.contains("workbench")))
	inv.add_building(fence, 2)
	inv.add_building(well)
	await stand(Vector2i(22, 16))
	await tap(BAG_AT)
	bag.build_button.pressed.emit()
	await wait(2)
	check("the list has only what's owned", pick.visible and pick._rows.get_child_count() == 2)
	check("with its count", pick._rows.get_child(0).text == "%s: 2" % fence.display_name)
	pick._rows.get_child(0).pressed.emit()
	await wait(3)
	check("Build mode is on", player.tool == 5 and player.selected_building() == fence)
	check("Action shows the building", controls._action_icon.texture == fence.preview_texture and controls._buttons["action"].modulate == Color.WHITE)
	check("the text says what's left", hud.tool_label.text.contains("2 left"))
	var cell := Vector2i(23, 16)
	await tap(ACTION_AT)
	check("Action places", farm.builder.placed.has(cell) and inv.building_count(fence) == 1)
	check("and can't till", not farm.is_tilled(cell))
	check("with more left, it stays on", player.tool == 5)
	await wait(3)
	check("facing a building shows the glove", controls._shown_action == farm.Action.PICK_UP)
	await tap(ACTION_AT)
	check("Action takes it back", not farm.builder.placed.has(cell) and inv.building_count(fence) == 2)
	await wait(3)
	await tap(ACTION_AT)
	await stand(Vector2i(22, 18))
	await tap(ACTION_AT)
	check("placing the last one ends Build mode", inv.building_count(fence) == 0 and player.tool == 0)
	await wait(3)
	check("Seed comes back", controls._buttons["seed_menu"].visible and not controls._buttons["build_mode"].visible)
	check("farming comes back", farm.smart_action(Vector2i(23, 13)) == farm.Action.TILL)
	inv.add_building(fence)
	controls.set_active(false)
	player.tool = 5
	await wait(2)
	inv.add_building(fence)
	farm.builder.place(cell, fence)
	await wait(3)
	check("computers keep the Hand for that", not farm.can_use(5, cell))

	print("ALL PASS" if fails == 0 else "%d FAILED" % fails)
	quit(fails)
