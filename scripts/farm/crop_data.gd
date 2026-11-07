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
## Optional frames side by side, played in a loop while ripe, in place of the last stage.
@export var ripe_animation: Texture2D
@export var ripe_frames: int = 4
@export var ripe_fps: float = 5.0
## If not clear, a ripe crop glows in this color, with rising motes, so it stands out.
@export var ripe_glow: Color = Color(0, 0, 0, 0)
## Placeholder color used until stages_texture exists.
@export var color: Color = Color.WHITE
## Above 0, the plant is poison to the curse: while growing and watered, it guards a square this
## many tiles out.
@export var ward_radius: int = 0
## How far it guards while growing and dry.
@export var ward_dry_radius: int = 0
## How far it guards once ripe, with no water needed.
@export var ward_ripe_radius: int = 0
## Above 0, harvesting bursts the plant and heals cursed land this many tiles away.
@export var burst_radius: int = 0
