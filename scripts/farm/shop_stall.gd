extends Area2D
## The seed shop stall. Interacting with it (F) opens the shop menu.


func interact(_player: Player) -> void:
	GameState.request_shop()
