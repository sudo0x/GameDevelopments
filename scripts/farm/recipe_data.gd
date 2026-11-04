class_name RecipeData
extends Resource
## One crafting recipe. Instances live in data/recipes/.

enum Result { HOLY_WATER, PURIFYING_HOE }

@export var display_name: String
@export var needs: Array[RecipeNeed] = []
@export var result: Result = Result.HOLY_WATER
@export var result_amount: int = 1
