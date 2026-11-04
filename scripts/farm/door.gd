extends Area2D
## The house door. Interacting with it (F) ends the day.


func interact(_player: Player) -> void:
	Audio.play(&"sleep")
	GameState.request_sleep()
