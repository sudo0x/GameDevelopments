class_name BuriedFind
extends Resource
## Treasure under a cursed cell. Healing the cell digs it up.

enum Kind { MONEY, SEEDS, HOLY_WATER }

@export var cell: Vector2i
@export var kind: Kind = Kind.MONEY
@export var amount: int = 1
## Which seeds, for Kind.SEEDS.
@export var crop: CropData
