extends PanelContainer
## The shop. One seed row per crop, built from GameState.CROPS, then holy water.
## The game pauses while it's open; this node keeps running (process_mode = Always).

var _labels: Array[Label] = []
var _buttons: Array[Button] = []

@onready var money_label: Label = $Margin/Box/MoneyLabel
@onready var rows: VBoxContainer = $Margin/Box/Rows


func _ready() -> void:
	for crop in GameState.CROPS:
		_add_row(GameState.buy_seed.bind(crop))
	_add_row(GameState.buy_holy_water)
	GameState.shop_requested.connect(open)
	GameState.inventory_changed.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		# Handled, so the same key press can't reach the player and reopen the shop.
		get_viewport().set_input_as_handled()
		close()


func open() -> void:
	_refresh()
	show()
	get_tree().paused = true
	for button in _buttons:
		if not button.disabled:
			button.grab_focus()
			break


func close() -> void:
	hide()
	get_tree().paused = false


func _add_row(buy: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var button := Button.new()
	button.pressed.connect(buy)
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
