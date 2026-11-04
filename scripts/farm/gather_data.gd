class_name GatherData
extends Resource
## One kind of gatherable object (tree, rock). Instances live in data/gather/.

@export var display_name: String
@export var material: MaterialData
@export var amount: int = 1
## Hits with the hand tool before it gives its material.
@export var hits: int = 3
@export var whole_texture: Texture2D
## What's left after gathering.
@export var remains_texture: Texture2D
## Whether what's left still blocks walking: a stump does, rubble doesn't.
@export var remains_solid: bool = true
