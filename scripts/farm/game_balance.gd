class_name GameBalance
extends Resource
## Numbers to tune without touching code. The one instance is data/balance.tres.

@export var holy_water_price: int = 30
## Holy water cleanses this many tiles out from the target: 1 makes a 3×3 patch.
@export var cleanse_radius: int = 1
## Cursed tiles the purifying hoe can heal each day.
@export var hoe_daily_uses: int = 5
## The first day creatures appear, so a new player has time to settle in.
@export var creature_first_day: int = 3
## How many creatures appear each morning, before counting how much land is healed.
@export var creature_base_count: int = 2
## One more creature for each this many percent of the island healed.
@export var creature_heal_percent_each: float = 5.0
## The most creatures at once, which also keeps phones running smoothly.
@export var creature_max_count: int = 6
## Creatures can't come closer than this to a lantern's light, in pixels.
@export var lantern_safe_radius: float = 96.0
## Hearts of damage one sword hit does.
@export var sword_damage: int = 1
## Hearts the player starts each day with.
@export var max_hearts: int = 5
## How much of their money the player loses when they faint, in percent.
@export var faint_money_percent: int = 10
## Holy water needed to restore the shrine.
@export var shrine_cost: int = 3
## How many tiles out the restored shrine heals.
@export var shrine_radius: int = 9
