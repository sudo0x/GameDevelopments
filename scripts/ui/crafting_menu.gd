extends GameMenu
## The workbench menu. One row per recipe, built from GameState.RECIPES.

## Narrower than other menus, so the panel leaves the touch buttons showing.
const MAKE_BUTTON_SIZE := Vector2(60, 36)

var _labels: Array[Label] = []
var _buttons: Array[Button] = []

@onready var rows: VBoxContainer = $Margin/Box/Scroll/Rows


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
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_icon(recipe.icon))
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var button := Button.new()
	button.custom_minimum_size = MAKE_BUTTON_SIZE
	button.pressed.connect(GameState.craft.bind(recipe))
	button.pressed.connect(Audio.play.bind(&"craft"))
	row.add_child(label)
	row.add_child(button)
	rows.add_child(row)
	_labels.append(label)
	_buttons.append(button)


func _refresh() -> void:
	for i in GameState.RECIPES.size():
		var recipe := GameState.RECIPES[i]
		var made := GameState.already_made(recipe)
		var details := GameState.controls(recipe.made_text, recipe.made_text_touch) if made else _needs_text(recipe)
		_labels[i].text = "%s\n%s" % [recipe.display_name, details]
		_buttons[i].text = "Made" if made else "Make"
		_buttons[i].disabled = not GameState.can_craft(recipe)


## Shows what's needed and what the player has, like "1 Radish (0), 1 Stone (3)".
func _needs_text(recipe: RecipeData) -> String:
	var parts: PackedStringArray = []
	for need in recipe.needs:
		parts.append("%d %s (%d)" % [need.amount, need.display_name(), GameState.owned(need)])
	return ", ".join(parts)
