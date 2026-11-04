class_name RecipeNeed
extends Resource
## One ingredient of a recipe: set either a crop or a material.

@export var crop: CropData
@export var material: MaterialData
@export var amount: int = 1


func display_name() -> String:
	return crop.display_name if crop else material.display_name
