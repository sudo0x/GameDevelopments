class_name BuildingData
extends Resource
## One kind of building the player can place. Instances live in data/buildings/.

@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
## For the preview before placing: the same art and offset as the scene's sprite.
@export var preview_texture: Texture2D
@export var preview_offset: Vector2
