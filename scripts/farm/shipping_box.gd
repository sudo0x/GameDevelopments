extends Area2D
## The shipping box. Interacting with it (F) puts every harvested crop in; they're paid overnight.


## An empty box has nothing to do, so the Action button can look past it.
func can_interact() -> bool:
	return Inventory.has_harvest()


func interact(_player: Player) -> void:
	if GameState.carry_mode and not Inventory.has_harvest():
		GameState.notice.emit("Nothing to ship. Carry crops in your bag.")
		return
	Inventory.ship_all()
	Audio.play(&"ship")
