# Cursed Island Farm (working title)

> Farm, craft and fight to cleanse a cursed island. Every field you grow pushes the darkness back.

A moody dark-fantasy 2D top-down farming game, made with **Godot 4.7** by a solo developer. Android first, then Steam.

![The hooded farmer next to fields of radishes, carrots and pumpkins, with the farmhouse and cursed land at the edge](docs/images/screenshot.png)

## Status

**In playtesting.** The whole game loop is built and runs on a phone: farming, the returning curse, crafting, building, combat and a story told through an old book. The balance isn't final, and outside players haven't tried it yet. [The concept](docs/03_2026-11-03_game-concept.md) describes the game, and the roadmap is in [`CLAUDE.md`](CLAUDE.md).

## Run it

1. Install [Godot 4.7](https://godotengine.org/download).
2. In Godot, click **Import** and select this folder's `project.godot`.
3. Press **F5**.

## Controls

**On a phone:** a joystick, and a big Action button that shows what it will do. Heal, Seed, Bag, Pause and Tasks are around it. Press and hold a building to move it.

| Key | Action |
|---|---|
| WASD / arrow keys | Move |
| R | Action: does what fits the tile or object in front of you |
| 1 to 7 | Hoe, watering can, seeds, hand, holy water, build, sword |
| Q / E | Change the seed, building or kind of holy water |
| Space / left click | Use the selected tool |
| F | Use the object nearby |
| I | Bag |
| B | Old book |
| G | Tasks |
| Esc | Pause |

## Project structure

| Folder | What's inside |
|---|---|
| `scenes/` | Godot scenes |
| `scripts/` | GDScript code, in the same folders as `scenes/` |
| `data/` | Game data: crops, buildings, recipes, balance numbers |
| `assets/` | Game-ready pixel art and sound |
| `art_source/` | Original AI-generated images (not loaded by the game) |
| `tools/` | Dev scripts: shrinking art, building the map, checking the pace |
| `tests/` | Automated tests. Run them all with `tests/run_all.sh` |
| `docs/` | Plans and logs. Start at [the index](docs/README.md) |
| `research/` | Notes from planning the game |

## Art

The font is [m5x7](https://managore.itch.io/m5x7) by Daniel Linssen (CC0). The pixel art is **AI-generated** (ChatGPT) from an original style reference, and will be disclosed where stores require it.
