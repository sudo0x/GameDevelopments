class_name BuildingData
extends Resource
## One kind of building the player can place. Instances live in data/buildings/.

@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
## For the preview before placing: the same art and offset as the scene's sprite.
@export var preview_texture: Texture2D
@export var preview_offset: Vector2
## If above 0, heals the nearest cursed tile within this many tiles each night.
@export var heal_radius: int = 0
## Can't be crafted: it only exists because the map starts with one, so the Build tool
## skips it unless one is in the bag.
@export var starting_only := false
## If above 0, waters all soil this many tiles out each morning: 2 makes a 5×5 area.
@export var water_radius: int = 0
