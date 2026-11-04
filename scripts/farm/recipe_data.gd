class_name RecipeData
extends Resource
## One crafting recipe. Instances live in data/recipes/.

enum Result { HOLY_WATER, PURIFYING_HOE, BUILDING, SWORD }

@export var display_name: String
@export var needs: Array[RecipeNeed] = []
@export var result: Result = Result.HOLY_WATER
@export var result_amount: int = 1
## Shown in the crafting menu once a one-time recipe has been made.
@export var made_text: String
## Which building, for Result.BUILDING.
@export var building: BuildingData
