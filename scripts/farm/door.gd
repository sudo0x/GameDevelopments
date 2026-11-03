extends Area2D
## The house door. Interacting with it (F) ends the day.


func interact(_player: Player) -> void:
	GameState.request_sleep()
