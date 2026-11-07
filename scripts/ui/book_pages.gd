class_name BookPages
extends RefCounted
## The old book's pages. Each row is the percent of the island healed that reveals it, its
## title, and its text, kept short for a phone screen. {action} and {heal} become the player's
## own controls. Keep the percents in order.

const PAGES: Array[Array] = [
	[0.0, "The last green land", "A curse is killing this island. Your farm is the last green land.\n\nThis book was left in the house. Its pages are stained black. Perhaps healing the land will clear them."],
	[0.0, "Working the land", "Face the ground and use {action}. It tills grass, plants seeds, waters crops and picks them when ripe.\n\nCrops grow while you sleep, but only if watered. The can holds ten, and a well refills it. Sell your harvest in the shipping box."],
	[0.0, "Healing the land", "Holy water heals cursed land: use {heal} beside it. Buy more at the stall.\n\nThe curse returns at night. Lanterns and wardthorn guard the land around them: face one to see how far."],
	[0.0, "The night trader", "A note in fresh ink:\n\n\"Someone rows in after dark. I have never seen their face.\n\nWhat I leave in the box is gone by morning, with coins in its place. The stall is stocked too, but never with more than three bottles.\""],
	[1.0, "The first page clears", "\"We came for the good soil. The harvests were heavy, and we thanked no one for them.\n\nThe shrines stood empty. Nobody noticed when their lights went out.\""],
	[3.0, "Things in the dark", "\"Shades drift where the ground has died. They hate lantern light.\n\nHollows walk the old farmlands. They wear what is left of us, and they don't know our names.\""],
	[6.0, "Wardthorn", "\"The curse will not touch wardthorn. My mother planted it around the fields, and we laughed at her.\n\nWe pulled it up to make room for more crops. That was the first year the ground turned black.\""],
	[12.0, "The heart", "\"It began at the middle of the island, under the hill. We called it the heart, because it beats.\n\nAt night, you can feel it through the soil.\""],
	[25.0, "The shrines", "\"Three shrines held it down. One still stands to the east, past the old farmlands.\n\nGive it holy water, and it may wake again.\""],
	[50.0, "The last of us", "\"The boats are gone. I am leaving this book in the house, for whoever comes.\n\nIf you are reading this, the land is answering you. It never answered us.\""],
]


## How many pages this much healed land reveals.
static func count_for(percent: float) -> int:
	var count := 0
	for page in PAGES:
		if percent >= page[0]:
			count += 1
	return count
