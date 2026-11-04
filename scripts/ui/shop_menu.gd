extends GameMenu
## The shop. One seed row per crop, built from GameState.CROPS, then holy water.

var _labels: Array[Label] = []
var _buttons: Array[Button] = []

@onready var money_label: Label = $Margin/Box/MoneyLabel
@onready var rows: VBoxContainer = $Margin/Box/Rows


func _ready() -> void:
	for crop in GameState.CROPS:
		_add_row(GameState.buy_seed.bind(crop), crop.seed_icon)
	_add_row(GameState.buy_holy_water, HOLY_WATER_ICON)
	GameState.shop_requested.connect(open)
	super()
	_refresh()


func _focus_first_button() -> void:
	for button in _buttons:
		if not button.disabled:
			button.grab_focus()
			break


func _add_row(buy: Callable, icon: Texture2D) -> void:
	var row := HBoxContainer.new()
	row.add_child(_icon(icon))
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var button := Button.new()
	button.custom_minimum_size = BUTTON_SIZE
	button.pressed.connect(buy)
	button.pressed.connect(Audio.play.bind(&"buy"))
	row.add_child(label)
	row.add_child(button)
	rows.add_child(row)
	_labels.append(label)
	_buttons.append(button)


func _refresh() -> void:
	money_label.text = "Money: %d" % GameState.money
	for i in GameState.CROPS.size():
		var crop := GameState.CROPS[i]
		_labels[i].text = "%s seeds: %d" % [crop.display_name, GameState.seed_count(crop)]
		_set_price(i, crop.seed_price)
	var last := _labels.size() - 1
	_labels[last].text = "Holy water: %d" % GameState.holy_water
	_set_price(last, GameState.BALANCE.holy_water_price)


func _set_price(row: int, price: int) -> void:
	_buttons[row].text = "Buy for %d" % price
	_buttons[row].disabled = GameState.money < price
