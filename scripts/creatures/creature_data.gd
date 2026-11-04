class_name CreatureData
extends Resource
## One kind of creature. Instances live in data/creatures/.

@export var id: StringName
@export var display_name: String
@export var texture: Texture2D
## Sword hits it takes to defeat, at 1 damage each.
@export var max_health: int = 2
## Hearts it takes from the player on contact.
@export var damage: int = 1
## How high it bobs: 0 for something heavy that walks.
@export var float_height: float = 3.0
## Radius of its body, in pixels.
@export var body_radius: float = 8.0
## How far a hit pushes it: 1 is normal, less for something heavy.
@export var knockback_scale: float = 1.0
## It only appears at this column of the map or further east.
@export var min_cell_x: int = 0
## What it leaves behind when defeated.
@export var drop: MaterialData
@export var drop_amount: int = 1
@export var wander_speed: float = 20.0
@export var chase_speed: float = 55.0
## It wanders this far from where it started.
@export var wander_radius: float = 64.0
## It starts chasing when the player is this close.
@export var chase_range: float = 110.0
## It gives up when the player is this far away.
@export var lose_range: float = 170.0
