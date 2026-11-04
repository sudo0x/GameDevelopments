extends PointLight2D
## Makes a lantern's light flicker gently, like a small flame.

@export var flicker_amount: float = 0.12
@export var flicker_speed: float = 6.0

@onready var _base_energy: float = energy
## A random start, so lanterns don't all flicker together.
@onready var _time: float = randf_range(0.0, 100.0)


func _process(delta: float) -> void:
	_time += delta
	var wave := sin(_time * flicker_speed) + 0.5 * sin(_time * flicker_speed * 2.3)
	energy = _base_energy + flicker_amount * wave / 1.5
