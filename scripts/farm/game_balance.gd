class_name GameBalance
extends Resource
## Numbers to tune without touching code. The one instance is data/balance.tres.

@export var holy_water_price: int = 30
## Holy water cleanses this many tiles out from the target: 1 makes a 3×3 patch.
@export var cleanse_radius: int = 1
## Cursed tiles the purifying hoe can heal each day.
@export var hoe_daily_uses: int = 5
## Hearts the player starts each day with.
@export var max_hearts: int = 5
## How much of their money the player loses when they faint, in percent.
@export var faint_money_percent: int = 10
## Holy water needed to restore the shrine.
@export var shrine_cost: int = 3
## How many tiles out the restored shrine heals.
@export var shrine_radius: int = 9
