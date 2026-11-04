class_name CropData
extends Resource
## One crop type (radish, carrot, ...). Instances live in data/crops/.

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var seed_icon: Texture2D
@export var days_to_grow: int = 3
@export var seed_price: int = 10
@export var sell_price: int = 25
## 4 growth stages side by side: seed, sprout, growing, ripe. Optional until the art exists.
@export var stages_texture: Texture2D
## Placeholder color used until stages_texture exists.
@export var color: Color = Color.WHITE
