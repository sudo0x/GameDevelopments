class_name BasicWeapons
extends RefCounted
## Six cheap early weapons, weaker than the sword and bow (docs/28_..., finding 98). Every hit
## still does 1 heart, so each is weaker in reach, speed or ammo instead. Melee ones reuse the
## sword's swing with their own picture and numbers; throwing ones reuse the arrow's flight with
## a pebble, and spend a carried stone each. All the numbers are here, to tune in one place.

const ICONS := preload("res://assets/items/basic_weapons.png")
const ICON_SIZE := 32.0
const PEBBLE := preload("res://assets/objects/pebble.png")
## In the icon strip's order.
const IDS: Array[StringName] = [&"club", &"pitchfork", &"sickle", &"torch", &"sling", &"stones"]
## A torch burns out after this many swings, and a new one must be made.
const TORCH_SWINGS := 20
## reach: how far ahead the hit lands; size: how big the hit area is; arc: degrees each side of
## the swing; swing and cooldown: seconds; push: how much harder than the sword it knocks back.
## Throwing ones: range and speed in pixels, like the bow's.
const STATS: Dictionary[StringName, Dictionary] = {
	&"club": {"name": "Wooden club", "short": "Club", "reach": 20.0, "size": 18.0, "arc": 55.0, "swing": 0.32, "cooldown": 0.3},
	&"pitchfork": {"name": "Pitchfork", "short": "Fork", "reach": 34.0, "size": 12.0, "arc": 8.0, "swing": 0.3, "cooldown": 0.3},
	&"sickle": {"name": "Sickle", "reach": 16.0, "size": 14.0, "arc": 70.0, "swing": 0.12, "cooldown": 0.08},
	&"torch": {"name": "Torch", "reach": 18.0, "size": 16.0, "arc": 60.0, "swing": 0.24, "cooldown": 0.2, "push": 2.5},
	&"sling": {"name": "Sling", "throw": true, "range": 120.0, "speed": 240.0, "cooldown": 0.45},
	&"stones": {"name": "Throwing stones", "short": "Stones", "throw": true, "range": 80.0, "speed": 200.0, "cooldown": 0.4},
}
const TEXTS: Dictionary[StringName, String] = {
	&"club": "A heavy branch. Slow, and it doesn't reach far.",
	&"pitchfork": "Jabs straight ahead. Reaches far, but only in a thin line, and slowly.",
	&"sickle": "Quick little cuts, very close in.",
	&"torch": "Pushes creatures back hard. Burns out after 20 swings.",
	&"sling": "Throws a pebble, not as far as the bow. Each throw uses a carried stone.",
	&"stones": "Thrown by hand, the shortest range. Each throw uses a carried stone.",
}


static func has(item: StringName) -> bool:
	return STATS.has(item)


static func throws(item: StringName) -> bool:
	return STATS.has(item) and STATS[item].get("throw", false)


static func icon(item: StringName) -> Texture2D:
	var texture := AtlasTexture.new()
	texture.atlas = ICONS
	texture.region = Rect2(IDS.find(item) * ICON_SIZE, 0, ICON_SIZE, ICON_SIZE)
	return texture
