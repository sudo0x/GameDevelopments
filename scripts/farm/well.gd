extends Area2D
## Any well, built or from the map. Using it refills the watering can, so water is a trip to
## plan around, and where a well stands matters.


## A full can has nothing to gain, so the Action button can look past it.
func can_interact() -> bool:
	return Inventory.can_water < GameState.BALANCE.can_capacity


func interact(_player: Player) -> void:
	Inventory.fill_can()
	Audio.play(&"water")
	GameState.notice.emit("The watering can is full.")
