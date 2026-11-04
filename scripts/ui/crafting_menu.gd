extends GameMenu
## The workbench menu. One row per recipe, built from GameState.RECIPES.

var _labels: Array[Label] = []
var _buttons: Array[Button] = []

@onready var rows: VBoxContainer = $Margin/Box/Rows


func _ready() -> void:
	for recipe in GameState.RECIPES:
		_add_row(recipe)
	GameState.crafting_requested.connect(open)
	super()
	_refresh()


func _focus_first_button() -> void:
	for button in _buttons:
		if not button.disabled:
			button.grab_focus()
			break


func _add_row(recipe: RecipeData) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var button := Button.new()
	button.text = "Make"
	button.pressed.connect(GameState.craft.bind(recipe))
	row.add_child(label)
	row.add_child(button)
	rows.add_child(row)
	_labels.append(label)
	_buttons.append(button)


func _refresh() -> void:
	for i in GameState.RECIPES.size():
		var recipe := GameState.RECIPES[i]
		_labels[i].text = "%s\n%s" % [recipe.display_name, _needs_text(recipe)]
		_buttons[i].disabled = not GameState.can_craft(recipe)


## Shows what's needed and what the player has, like "2 Radish (0), 1 Stone (3)".
func _needs_text(recipe: RecipeData) -> String:
	var parts: PackedStringArray = []
	for need in recipe.needs:
		parts.append("%d %s (%d)" % [need.amount, need.display_name(), GameState.owned(need)])
	return ", ".join(parts)
