extends Area2D
## The storage chest by the house (storage controls only, docs/28_...). Everything the player
## owns but doesn't carry waits here. Using it opens the storage menu.


func _ready() -> void:
	# The old controls have no storage: everything owned is carried.
	if not GameState.carry_mode:
		get_parent().queue_free()


func interact(_player: Player) -> void:
	GameState.request_storage()
