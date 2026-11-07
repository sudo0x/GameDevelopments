extends GameMenu
## The shop. One seed row per crop, built from Inventory.CROPS, then holy water.

var _labels: Array[Label] = []
var _buttons: Array[Button] = []

@onready var money_label: Label = $Margin/Box/MoneyLabel
@onready var rows: VBoxContainer = $Margin/Box/Rows


func _ready() -> void:
	for crop in Inventory.CROPS:
		_add_row(Inventory.buy_seed.bind(crop), crop.seed_icon)
	_add_row(Inventory.buy_holy_water, HOLY_WATER_ICON)
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
	money_label.text = "Money: %d" % Inventory.money
	for i in Inventory.CROPS.size():
		var crop := Inventory.CROPS[i]
		_labels[i].text = "%s seeds: %d" % [crop.display_name, Inventory.seed_count(crop)]
		_set_price(i, crop.seed_price)
	var last := _labels.size() - 1
	var left := Inventory.holy_water_left_today()
	_labels[last].text = "Holy water: %d (%d left)" % [Inventory.holy_water, left]
	_set_price(last, GameState.BALANCE.holy_water_price)
	if left <= 0:
		_buttons[last].text = "Sold out"
		_buttons[last].disabled = true


func _set_price(row: int, price: int) -> void:
	_buttons[row].text = "Buy for %d" % price
	_buttons[row].disabled = Inventory.money < price
