extends Area2D
## The shipping box. Interacting with it (F) puts every harvested crop in; they're paid overnight.


func interact(_player: Player) -> void:
	GameState.ship_all()
