class_name CreatureData
extends Resource
## One kind of creature. Instances live in data/creatures/.

@export var id: StringName
@export var display_name: String
@export var texture: Texture2D
@export var wander_speed: float = 20.0
@export var chase_speed: float = 55.0
## It wanders this far from where it started.
@export var wander_radius: float = 64.0
## It starts chasing when the player is this close.
@export var chase_range: float = 110.0
## It gives up when the player is this far away.
@export var lose_range: float = 170.0
