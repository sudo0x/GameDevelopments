class_name RecipeNeed
extends Resource
## One ingredient of a recipe: set a crop, a material, or holy_water.

@export var crop: CropData
@export var material: MaterialData
@export var holy_water: bool = false
@export var amount: int = 1


func display_name() -> String:
	if holy_water:
		return "Holy water"
	return crop.display_name if crop else material.display_name
