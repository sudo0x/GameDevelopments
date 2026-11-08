class_name ItemInfo
extends RefCounted
## What every item is, in one place: its kind (the tab it's under) and a one-line description
## for the details side of the item menus. A new item needs a line here, not new menu code.
## Crops and seeds are described from their data, so new crops need nothing.

const SEEDS := "Seeds"
const CROPS := "Crops"
const TOOLS := "Tools"
const BUILD := "Build"
const WEAPONS := "Weapons"
const MATERIALS := "Materials"

const TEXTS: Dictionary[StringName, String] = {
	&"hoe": "Tills grass into soil. Once purified, it also heals single cursed tiles.",
	&"can": "Waters soil. Wells fill it up again.",
	&"holy_water": "Heals a 3x3 patch of cursed land.",
	&"strong_holy_water": "Heals a 5x5 patch of cursed land.",
	&"purifying_hoe": "Lets the hoe heal one cursed tile, a few times a day.",
	&"sword": "Hits creatures close by.",
	&"bow": "Shoots arrows at creatures up to five tiles away.",
	&"arrows": "The bow uses one per shot.",
	&"mat_wood": "From trees. For building and crafting.",
	&"mat_stone": "From rocks. For building and crafting.",
	&"mat_curse_shard": "Dropped by creatures. For lanterns, strong holy water and the bow.",
	&"build_lantern_post": "Guards a 5x5 area from the curse, and heals a tile each night.",
	&"build_fence": "Blocks the way. Good for paths and pens.",
	&"build_well": "Fills the can, and waters the soil around it each morning.",
	&"build_shipping_box": "Crops put in it are sold overnight.",
	&"build_workbench": "Where tools and buildings are made.",
	&"build_old_lantern_post": "An old lamp. Its light keeps creatures away.",
	&"bag_upgrade": "Carry 4 more kinds of items.",
}


## What each farm and build job does, for the bag page.
const JOB_TEXTS: Dictionary[StringName, String] = {
	&"till": "The big button tills the grass ahead with the hoe.",
	&"plant": "Plants the seeds to plant, first in the order first.",
	&"water": "Waters dry soil with the can.",
	&"harvest": "Picks ripe crops. Off, they stay in the ground for their looks.",
	&"gather": "Hits trees and rocks for wood and stone.",
	&"heal": "Heals a cursed tile ahead, with the purifying hoe or holy water.",
	&"place": "The big button places the first building in the order below, from the bag.",
	&"move": "The big button lifts the building in front of you. Walk, then tap again to put it down. It never goes in the bag.",
	&"pick_up": "The big button puts the building in front of you in the bag, to carry it or keep it in storage.",
}


static func kind(item: StringName) -> String:
	var text := String(item)
	if text.begins_with("seed_"):
		return SEEDS
	if text.begins_with("crop_"):
		return CROPS
	if text.begins_with("mat_"):
		return MATERIALS
	if text.begins_with("build_"):
		return BUILD
	if item in [&"sword", &"bow", &"arrows"]:
		return WEAPONS
	return TOOLS


static func describe(item: StringName) -> String:
	if TEXTS.has(item):
		return TEXTS[item]
	var text := String(item)
	if text.begins_with("seed_") or text.begins_with("crop_"):
		var crop := Inventory.crop_by_id(StringName(text.substr(5)))
		if crop.ward_radius > 0:
			return "Guards the land around it from the curse while it grows. Rare."
		if text.begins_with("seed_"):
			return "Grows in %d days if watered. Sells for %d." % [crop.days_to_grow, crop.sell_price]
		return "Sells for %d at the shipping box." % crop.sell_price
	return ""


## The bag item a recipe makes, so a recipe and the item share a description.
static func recipe_item(recipe: RecipeData) -> StringName:
	match recipe.result:
		RecipeData.Result.HOLY_WATER:
			return &"holy_water"
		RecipeData.Result.STRONG_HOLY_WATER:
			return &"strong_holy_water"
		RecipeData.Result.PURIFYING_HOE:
			return &"purifying_hoe"
		RecipeData.Result.BUILDING:
			return Inventory.building_item(recipe.building)
		RecipeData.Result.SWORD:
			return &"sword"
		RecipeData.Result.BOW:
			return &"bow"
		RecipeData.Result.ARROWS:
			return &"arrows"
	return &""
