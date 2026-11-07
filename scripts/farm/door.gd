extends Area2D
## The house door. Interacting with it (F) ends the day.


## The Action button does many jobs, so it asks first. F only ever means this.
func action_interact(_player: Player) -> void:
	GameState.ask_sleep()


func interact(_player: Player) -> void:
	Audio.play(&"sleep")
	GameState.request_sleep()
