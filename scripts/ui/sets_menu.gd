class_name SetsMenu
extends ItemGridMenu
## Storage controls (docs/28_...): the bag page, in the same layout as the workbench, stall and
## storage. The Ready tab shows what the big button uses, in order: the farm jobs, the seeds to
## plant, the combat set and the build set. The other tabs show what's carried, by kind. The
## details side says what an item is and does, with buttons to add it to its set, take it out,
## or move it sooner. Key I or the Bag button opens it.

const READY := "Ready"
const JOB_NAMES: Dictionary[StringName, String] = {
	&"till": "Till", &"plant": "Plant", &"water": "Water", &"harvest": "Harvest", &"gather": "Gather", &"heal": "Heal",
	&"place": "Place", &"pick_up": "Pick up",
}
## The job icons, side by side in Inventory.FARM_JOBS order.
const JOB_ICONS := preload("res://assets/ui/job_icons.png")
const JOB_ICON_SIZE := 32.0
## The build job icons, side by side in Inventory.BUILD_JOBS order.
const BUILD_JOB_ICONS := preload("res://assets/ui/build_job_icons.png")
const ORDINALS: Array[String] = ["1st", "2nd", "3rd"]

## Each part in words, for tests.
var carried_text := ""
var jobs_text := ""
var plant_text := ""
var combat_text := ""
var build_text := ""


func _init() -> void:
	super()
	name = "SetsMenu"
	close_action = &"inventory"
	keyboard_help = "I / Esc: close"
	touch_help = ""


func _unhandled_input(event: InputEvent) -> void:
	if GameState.carry_mode and not visible and not get_tree().paused and event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		open()
	else:
		super(event)


func _menu_title() -> String:
	return "Bag: %d of %d kinds" % [Inventory.used_slots(), Inventory.bag_slots]


func _tab_list() -> Array[String]:
	return [READY, ALL, ItemInfo.SEEDS, ItemInfo.CROPS, ItemInfo.TOOLS, ItemInfo.BUILD, ItemInfo.WEAPONS, ItemInfo.MATERIALS]


func _first_tab() -> String:
	return READY


func _entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	# Grouped by mode: switches, then the items each mode uses, in order, each under a heading.
	var words: PackedStringArray = []
	words.append(_add_jobs(entries, Inventory.FARM_JOBS, "Farm jobs: tap to switch"))
	plant_text = _add_set(entries, Inventory.plant_set, "Seeds to plant, in order")
	combat_text = _add_set(entries, Inventory.combat_set, "Combat, in order")
	words.append(_add_jobs(entries, Inventory.BUILD_JOBS, "Build jobs: tap to switch"))
	build_text = _add_set(entries, Inventory.build_set, "Buildings to place, in order")
	jobs_text = ", ".join(words)
	words.clear()
	for item in Inventory.bag_items():
		entries.append({"id": item, "icon": KeyToolBar.item_icon(item), "kind": ItemInfo.kind(item), "count": _count(item)})
		words.append("%s %d" % [Inventory.item_name(item), Inventory.carried(item)])
	carried_text = ", ".join(words)
	return entries


## Job switches on the Ready tab: an off one is dimmed and says Off, and a tap flips it.
func _add_jobs(entries: Array[Dictionary], jobs: Array[StringName], section: String) -> String:
	var words: PackedStringArray = []
	for job in jobs:
		var on := Inventory.job_on(job)
		entries.append({
			"id": StringName("job_" + job), "icon": job_icon(job), "kind": READY, "count": "" if on else "Off",
			"dim": not on, "only_in_tab": true, "section": section, "on_tap": Inventory.toggle_job.bind(job),
		})
		words.append("%s %s" % [JOB_NAMES[job], "on" if on else "off"])
	return ", ".join(words)


## A set's items on the Ready tab, in order; one that ran out stays, dimmed.
func _add_set(entries: Array[Dictionary], ready: Array[StringName], section: String) -> String:
	var words: PackedStringArray = []
	for item in ready:
		var count := Inventory.carried(item)
		entries.append({
			"id": item, "icon": KeyToolBar.item_icon(item), "kind": READY, "count": _count(item),
			"dim": count == 0, "only_in_tab": true, "section": section,
		})
		words.append("%s %d" % [Inventory.item_name(item), count])
	return ", ".join(words)


func _count(item: StringName) -> String:
	return "" if item in [&"hoe", &"can", &"sword", &"bow"] else str(Inventory.carried(item))


func _details(id: StringName) -> Dictionary:
	if String(id).begins_with("job_"):
		return _job_details(StringName(String(id).substr(4)))
	var details := {
		"icon": KeyToolBar.item_icon(id),
		"name": Inventory.item_name(id),
		"text": ItemInfo.describe(id),
		"info": "In bag: %d" % Inventory.carried(id),
		"buttons": [],
	}
	if Inventory.can_set(id):
		_set_details(id, details)
	else:
		details["info"] += "\n" + _use_hint(id)
	return details


func _job_details(job: StringName) -> Dictionary:
	var on := Inventory.job_on(job)
	var group := "Build job" if Inventory.BUILD_JOBS.has(job) else "Farm job"
	return {
		"icon": job_icon(job),
		"name": "%s: %s" % [group, JOB_NAMES[job]],
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


static func job_icon(job: StringName) -> Texture2D:
	var icon := AtlasTexture.new()
	var build := Inventory.BUILD_JOBS.has(job)
	icon.atlas = BUILD_JOB_ICONS if build else JOB_ICONS
	var index := Inventory.BUILD_JOBS.find(job) if build else Inventory.FARM_JOBS.find(job)
	icon.region = Rect2(index * JOB_ICON_SIZE, 0, JOB_ICON_SIZE, JOB_ICON_SIZE)
	return icon
