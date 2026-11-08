class_name WorkbenchMenu
extends ItemGridMenu
## The workbench with storage controls: every recipe as a tile, its needs and a Make button on
## the right (docs/28_...). The classic row menu (CraftingMenu) stays for the older tests only.


func _init() -> void:
	super()
	name = "WorkbenchMenu"
	keyboard_help = "F / Esc: close"
	touch_help = ""


func _ready() -> void:
	super()
	GameState.crafting_requested.connect(func() -> void:
		if GameState.carry_mode:
			open())


func _menu_title() -> String:
	return "Workbench"


func _tab_names() -> Array[String]:
	return [ItemInfo.TOOLS, ItemInfo.BUILD, ItemInfo.WEAPONS]


func _entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for i in Inventory.RECIPES.size():
		var recipe := Inventory.RECIPES[i]
		entries.append({
			"id": StringName("recipe_%d" % i),
			"icon": recipe.icon,
			"kind": ItemInfo.kind(ItemInfo.recipe_item(recipe)),
			"count": "x%d" % recipe.result_amount if recipe.result_amount > 1 else "",
			"dim": not Inventory.can_craft(recipe),
		})
	return entries


func _details(id: StringName) -> Dictionary:
	var recipe := Inventory.RECIPES[int(String(id).substr(7))]
	var made := Inventory.already_made(recipe)
	var info := GameState.controls(recipe.made_text, recipe.made_text_touch) if made else _needs_text(recipe)
	var amount := " x%d" % recipe.result_amount if recipe.result_amount > 1 else ""
	return {
		"icon": recipe.icon,
		"name": recipe.display_name + amount,
		"text": ItemInfo.describe(ItemInfo.recipe_item(recipe)),
		"info": info,
		"buttons": [["Made" if made else "Make", _make.bind(recipe), Inventory.can_craft(recipe)]],
	}


func _make(recipe: RecipeData) -> void:
	if Inventory.craft(recipe):
		Audio.play(&"craft")


## One need per line, with what the player has, like "5 Wood (have 3)".
func _needs_text(recipe: RecipeData) -> String:
	var lines: PackedStringArray = ["Needs:"]
	for need in recipe.needs:
		lines.append("%d %s (have %d)" % [need.amount, need.display_name(), Inventory.owned(need)])
	return "\n".join(lines)
