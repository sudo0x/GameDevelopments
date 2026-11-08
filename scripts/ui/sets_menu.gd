class_name SetsMenu
extends ItemGridMenu
## Storage controls (docs/28_...): the bag, in the same layout as the workbench, stall and
## storage, with two pages picked at the top. Bag shows what's carried, by kind, and what each
## item is. Modes sets up what the big button does: one tab per mode, each with its switches,
## then its items in order, then the carried ones it doesn't use yet. Key I or the Bag button
## opens it, on the page it was last on.

const BAG := "Bag"
const MODES := "Modes"
## The Modes page's tabs, in Player.Mode order. "mode" in the name keeps them apart from the
## Bag page's kinds, like Build.
const MODE_TABS: Array[String] = ["Farm mode", "Combat mode", "Build mode"]
const JOB_NAMES: Dictionary[StringName, String] = {
	&"till": "Till", &"plant": "Plant", &"water": "Water", &"harvest": "Harvest", &"gather": "Gather", &"heal": "Heal",
	&"place": "Place", &"move": "Move", &"pick_up": "Pick up",
}
## The job icons, side by side in Inventory.FARM_JOBS order.
const JOB_ICONS := preload("res://assets/ui/job_icons.png")
const JOB_ICON_SIZE := 32.0
const ORDINALS: Array[String] = ["1st", "2nd", "3rd"]

## Each part in words, for tests.
var carried_text := ""
var jobs_text := ""
var plant_text := ""
var combat_text := ""
var build_text := ""

var _page := BAG
var _page_buttons: Dictionary[String, Button] = {}


func _init() -> void:
	super()
	name = "SetsMenu"
	close_action = &"inventory"
	keyboard_help = "I / Esc: close"
	touch_help = ""
	# The pages sit where the title was; the Bag button says how full the bag is.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 6)
	for page: String in [BAG, MODES]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 30)
		button.pressed.connect(show_page.bind(page))
		row.add_child(button)
		_page_buttons[page] = button
	_title.add_sibling(row)
	_title.hide()


func _unhandled_input(event: InputEvent) -> void:
	if GameState.carry_mode and not visible and not get_tree().paused and event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		open()
	else:
		super(event)


## Switches between the Bag and Modes pages.
func show_page(page: String) -> void:
	_page = page
	_tab = _first_tab()
	_picked = &""
	_refresh()


func _menu_title() -> String:
	_page_buttons[BAG].text = "Bag: %d of %d" % [Inventory.used_slots(), Inventory.bag_slots]
	_page_buttons[MODES].text = MODES
	for page in _page_buttons:
		_page_buttons[page].modulate = PICKED_COLOR if page == _page else Color.WHITE
	return "Bag: %d of %d kinds" % [Inventory.used_slots(), Inventory.bag_slots]


func _tab_list() -> Array[String]:
	if _page == MODES:
		return MODE_TABS
	return [ALL, ItemInfo.SEEDS, ItemInfo.CROPS, ItemInfo.TOOLS, ItemInfo.BUILD, ItemInfo.WEAPONS, ItemInfo.MATERIALS]


## The Modes page opens on the mode the player is in.
func _first_tab() -> String:
	if _page == BAG:
		return ALL
	var player := get_tree().get_first_node_in_group("player") as Player
	return MODE_TABS[player.mode] if player else MODE_TABS[0]


func _entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var words: PackedStringArray = []
	for item in Inventory.bag_items():
		words.append("%s %d" % [Inventory.item_name(item), Inventory.carried(item)])
	carried_text = ", ".join(words)
	if _page == BAG:
		for item in Inventory.bag_items():
			entries.append({"id": item, "icon": KeyToolBar.item_icon(item), "kind": ItemInfo.kind(item), "count": _count(item)})
		return entries
	var farm := MODE_TABS[0]
	jobs_text = _add_jobs(entries, farm)
	plant_text = _add_set(entries, farm, Inventory.plant_set, "Seeds to plant, in order")
	_add_unused(entries, farm, Inventory.plant_set, ItemInfo.SEEDS, "Not planting: tap one to add it")
	var combat := MODE_TABS[1]
	combat_text = _add_combat(entries, combat)
	var build := MODE_TABS[2]
	_add_build_tools(entries, build)
	build_text = _add_set(entries, build, Inventory.build_set, "Buildings to place, in order")
	_add_unused(entries, build, Inventory.build_set, ItemInfo.BUILD, "Not placing: tap one to add it")
	return entries


## Combat mode: one row per combat button (a, b and c beside the big button), with its three
## places in the order a tap goes through them. A weapon's place offers Take off and Use sooner;
## an empty place shows a plus, and offers the carried weapons to add.
func _add_combat(entries: Array[Dictionary], tab: String) -> String:
	var summaries: PackedStringArray = []
	for i in Inventory.COMBAT_BUTTONS:
		var slot := Inventory.combat_slot(i)
		var names: PackedStringArray = []
		for place in Inventory.WEAPONS_PER_BUTTON:
			var section := "Combat button %d" % (i + 1)
			if place < slot.size():
				names.append(Inventory.item_name(slot[place]))
				entries.append({
					"id": StringName("slot%d_%d" % [i, place]), "icon": KeyToolBar.item_icon(slot[place]),
					"kind": tab, "section": section,
				})
			else:
				entries.append({"id": StringName("slot%d_%d" % [i, place]), "icon": null, "kind": tab, "section": section, "plus": true})
		if not names.is_empty():
			summaries.append("%d: %s" % [i + 1, ", ".join(names)])
	return " | ".join(summaries)


## Farm jobs: each one switches on or off with a tap.
func _add_jobs(entries: Array[Dictionary], tab: String) -> String:
	var words: PackedStringArray = []
	for job in Inventory.FARM_JOBS:
		var on := Inventory.job_on(job)
		entries.append({
			"id": StringName("job_" + job), "icon": job_icon(job), "kind": tab, "switch": on,
			"section": "Jobs: tap to switch on or off", "on_tap": Inventory.toggle_job.bind(job),
		})
		words.append("%s %s" % [JOB_NAMES[job], "on" if on else "off"])
	return ", ".join(words)


## Build tools: only one is on, and a tap picks it.
func _add_build_tools(entries: Array[Dictionary], tab: String) -> void:
	for tool in Inventory.BUILD_TOOLS:
		entries.append({
			"id": StringName("job_" + tool), "icon": job_icon(tool), "kind": tab, "switch": Inventory.build_tool == tool,
			"section": "The big button: pick one", "on_tap": Inventory.set_build_tool.bind(tool),
		})


## A set's items, in order; one that ran out stays, dimmed.
func _add_set(entries: Array[Dictionary], tab: String, ready: Array[StringName], section: String) -> String:
	var words: PackedStringArray = []
	for item in ready:
		var count := Inventory.carried(item)
		entries.append({
			"id": item, "icon": KeyToolBar.item_icon(item), "kind": tab, "count": _count(item),
			"dim": count == 0, "section": section,
		})
		words.append("%s %d" % [Inventory.item_name(item), count])
	return ", ".join(words)


## Carried items of this kind that aren't in the set, so they can be added from here.
func _add_unused(entries: Array[Dictionary], tab: String, ready: Array[StringName], kind: String, section: String) -> void:
	for item in Inventory.bag_items():
		if ItemInfo.kind(item) == kind and Inventory.can_set(item) and not ready.has(item):
			entries.append({
				"id": item, "icon": KeyToolBar.item_icon(item), "kind": tab, "count": _count(item),
				"dim": true, "section": section, "on_tap": Inventory.toggle_in_set.bind(item),
			})


func _count(item: StringName) -> String:
	return str(Inventory.carried(item)) if Inventory.shows_count(item) else ""


func _details(id: StringName) -> Dictionary:
	if String(id).begins_with("job_"):
		return _job_details(StringName(String(id).substr(4)))
	if String(id).begins_with("slot"):
		return _slot_details(id)
	var details := {
		"icon": KeyToolBar.item_icon(id),
		"name": Inventory.item_name(id),
		"text": ItemInfo.describe(id),
		"info": "In bag: %d" % Inventory.carried(id),
		"buttons": [],
	}
	if Inventory.can_set(id):
		if Inventory.is_weapon(id):
			_combat_details(id, details)
		else:
			_set_details(id, details)
	else:
		details["info"] += "\n" + _use_hint(id)
	return details


## A weapon on the Bag page: which combat buttons use it. They're set on the Modes page.
func _combat_details(id: StringName, details: Dictionary) -> void:
	var used: PackedStringArray = []
	for i in 3:
		if Inventory.combat_slot(i).has(id):
			used.append(str(i + 1))
	details["info"] += "\nCombat buttons: %s" % (", ".join(used) if not used.is_empty() else "none")
	details["info"] += "\nSet them on the Modes page."


## A weapon in one combat button's row on the Modes page.
func _slot_details(id: StringName) -> Dictionary:
	var index := int(String(id).substr(4, 1))
	var place := int(String(id).substr(6))
	var slot := Inventory.combat_slot(index)
	if place >= slot.size():
		# An empty place: a tile for each carried weapon that isn't on any button yet, since a
		# weapon goes on one button only.
		var buttons: Array = []
		for item in Inventory.bag_items():
			if Inventory.is_weapon(item) and Inventory.combat_button_of(item) < 0:
				buttons.append([Inventory.short_name(item), Inventory.toggle_in_combat_slot.bind(item, index), true, KeyToolBar.item_icon(item)])
		return {
			"name": "Add to button %d" % (index + 1),
			"text": "Pick a free weapon:" if not buttons.is_empty() else "No free weapons. Each weapon goes on one button, so take one off another button first, or make one at the workbench.",
			"buttons": buttons,
		}
	var item := slot[place]
	return {
		"icon": KeyToolBar.item_icon(item),
		"name": "Button %d: %s" % [index + 1, Inventory.item_name(item)],
		"text": ItemInfo.describe(item),
		"info": "%s of %d on this button" % [ORDINALS[place], slot.size()],
		"buttons": [
			["Take off", Inventory.toggle_in_combat_slot.bind(item, index), true],
			["Use sooner", Inventory.move_combat_sooner.bind(item, index), place > 0],
		],
	}


func _job_details(job: StringName) -> Dictionary:
	if Inventory.BUILD_TOOLS.has(job):
		var in_use := Inventory.build_tool == job
		return {
			"icon": job_icon(job),
			"name": "Build mode: %s" % JOB_NAMES[job],
			"text": ItemInfo.JOB_TEXTS[job],
			"info": "In use" if in_use else "Not in use. The build tool button (V) changes it too.",
			"buttons": [["Use this", Inventory.set_build_tool.bind(job), not in_use]],
		}
	var on := Inventory.job_on(job)
	return {
		"icon": job_icon(job),
		"name": "Farm job: %s" % JOB_NAMES[job],
		"text": ItemInfo.JOB_TEXTS[job],
		"info": "On" if on else "Off",
		"buttons": [["Turn off" if on else "Turn on", Inventory.toggle_job.bind(job), true]],
	}


## Seeds, weapons and buildings: where they are in their set, with buttons to add, remove and
## move sooner.
func _set_details(id: StringName, details: Dictionary) -> void:
	var ready := Inventory.set_for(id)
	var at := ready.find(id)
	var words: Array = _set_words(id)
	if at >= 0:
		details["info"] += "\n%s: %s" % [words[0], ORDINALS[at] if at < ORDINALS.size() else "%dth" % (at + 1)]
		details["buttons"] = [
			[words[2], Inventory.toggle_in_set.bind(id), true],
			[words[3], Inventory.move_sooner.bind(id), at > 0],
		]
	else:
		details["info"] += "\n%s: no" % words[0]
		details["buttons"] = [[words[1], Inventory.toggle_in_set.bind(id), Inventory.carried(id) > 0]]


## The words for a set: its name, then add, remove and sooner.
func _set_words(id: StringName) -> Array:
	if String(id).begins_with("seed_"):
		return ["Planting", "Plant it", "Don't plant", "Plant sooner"]
	if String(id).begins_with("build_"):
		return ["Build order", "Ready to build", "Not now", "Build sooner"]
	return ["Combat order", "Use in combat", "Don't use", "Use sooner"]


## What an item that can't go in a set is for.
func _use_hint(id: StringName) -> String:
	match ItemInfo.kind(id):
		ItemInfo.CROPS:
			return "Sell it at the shipping box."
		ItemInfo.MATERIALS:
			return "Use it at the workbench."
	if id in [&"holy_water", &"strong_holy_water"]:
		return "The Heal job uses it."
	if id == &"arrows":
		return "The bow uses them."
	return "Farm jobs use it."


## Farm jobs come from job_icons.png, and the build tools from the build tool strip.
static func job_icon(job: StringName) -> Texture2D:
	if Inventory.BUILD_TOOLS.has(job):
		return TouchControls.build_tool_icon(job)
	var icon := AtlasTexture.new()
	icon.atlas = JOB_ICONS
	icon.region = Rect2(Inventory.FARM_JOBS.find(job) * JOB_ICON_SIZE, 0, JOB_ICON_SIZE, JOB_ICON_SIZE)
	return icon


## Opens straight on one page and tab, for the empty combat buttons.
func open_on(page: String, tab: String) -> void:
	_page = page
	open()
	_tab = tab
	_refresh()
