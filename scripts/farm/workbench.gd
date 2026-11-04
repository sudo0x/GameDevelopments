extends Area2D
## The workbench. Interacting with it (F) opens the crafting menu.


func interact(_player: Player) -> void:
	GameState.request_crafting()
