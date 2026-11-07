class_name GameBalance
extends Resource
## Numbers to tune without touching code. The one instance is data/balance.tres.

@export var holy_water_price: int = 30
## Holy water in the bag on a new game, so the player can heal on day 1.
@export var start_holy_water: int = 2
## Holy water cleanses this many tiles out from the target: 1 makes a 3×3 patch.
@export var cleanse_radius: int = 1
## The same for strong holy water: 2 makes a 5×5 patch.
@export var strong_cleanse_radius: int = 2
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
## The Action button swings the sword when a creature is this close, in pixels.
## A little more than the sword's own reach of about 44.
@export var action_swing_distance: float = 48.0
## Tilled soil with no crop turns back into grass after this many nights.
@export var soil_idle_nights: int = 3
## Hearts the player starts each day with.
@export var max_hearts: int = 5
## How much of their money the player loses when they faint, in percent.
@export var faint_money_percent: int = 10
## Holy water needed to restore the shrine.
@export var shrine_cost: int = 3
## How many tiles out the restored shrine heals.
@export var shrine_radius: int = 9
## The first day whose night the curse takes healed land back.
@export var curse_return_first_day: int = 4
## Healed tiles the curse takes back each night. 0 turns this off.
@export var curse_return_per_night: int = 3
## The curse takes one more tile a night for each of these percent of the island healed.
@export var curse_growth_percent: float = 5.0
## Money from harvesting a crop the curse blighted, on top of a curse shard.
@export var blighted_crop_money: int = 5
## Holy water the stall can sell in one day, so money alone can't beat the curse.
@export var holy_water_daily_limit: int = 3
