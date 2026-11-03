# Project guide for Claude

## Engine
- Godot 4.7.2, GDScript, Compatibility renderer (for web and mobile)
- Executable: `C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe` (use `--headless` for checks)
- Platform: Windows dev; targets Android first, then Steam

## Game
- Moody dark-fantasy 2D top-down farming game: farming heals a cursed island (concept: `docs/03_2026-11-03_game-concept.md`)
- Built in layers: farming → curse/cleansing → collect/craft → build → combat → mobile/release
- Current layer plan: `docs/01_2026-11-03_layer-1-farming.md`; read it before adding gameplay features
- Art: AI-generated 32×32 pixel art, prompts in `docs/02_2026-11-03_art-prompts-layer-1.md`; use colored placeholders until an asset exists
- Lighting: art is neutral daylight; mood comes from `CanvasModulate` and `PointLight2D`, never baked into sprites

## Current status (keep this updated at the end of each work session)
- Last updated: 2026-11-03
- Done: research notes 01–04, game concept (docs/03), Layer 1 plan (docs/01), art prompts (docs/02), Godot project setup (Layer 1 step 1)
- Art: style reference chosen and saved (`assets/style_reference.png`, dark fantasy); next asset is the hooded player in 4 directions
- **Next:** Layer 1 step 2, player movement (8 directions, camera follow, test walls, colored placeholder until the player art arrives)
- Unknown: whether the user has used Godot before; ask, and if new, explain Godot concepts by comparing them to Angular

## Display and input
- Base resolution 640×360 (20×11 tiles of 32px), window 1280×720, stretch mode `viewport`, integer scaling
- Texture filter Nearest, 2D transforms snap to pixel
- Input actions (in `project.godot`): `move_up/down/left/right`, `tool_1`–`tool_4`, `seed_prev`, `seed_next`, `use_tool`, `interact`

## Folder layout
- `scenes/`: `.tscn` scenes by feature (main/, player/, farm/, ui/)
- `scripts/`: `.gd` scripts mirroring `scenes/`, plus `autoload/`
- `data/`: game data (crop definitions, prices)
- `assets/`: tiles/, crops/, items/, tools/, objects/, player/ (binary art, don't read)
- `docs/`: design and build plans; `research/`: research notes

## Code style
- GDScript with static typing (`var speed: float = 200.0`, typed function args/returns)
- snake_case for files, variables and functions; PascalCase for `class_name` and nodes
- Signals for communication between nodes; avoid deep `get_node("../../..")` paths
- Autoloads (singletons) only for truly global state (e.g. `GameState`, `AudioManager`)
- Export tunable values with `@export` so they can be tweaked in the editor

## Docs and research notes
- Name every new doc `NN_YYYY-MM-DD_short-name.md` (next order number in its folder, date created, kebab-case name)
- Put `**Date:** YYYY-MM-DD` right under the title of each doc
- Add each new doc to its folder's `README.md` index (number, date, link)
- Flows, loops, steps, timelines and architecture: use a ` ```mermaid ` block inside the `.md` (GitHub renders it, and it's far cheaper than SVG)
- Only for pictures Mermaid can't draw (game scenes, view styles): SVG in an `images/` subfolder, with hardcoded colors and a white background

## Working rules
- Keep changes focused on the requested feature; don't refactor unrelated code
- Don't open or edit `.godot/`, `.import` files or binary assets
- Prefer editing `.gd` scripts; edit `.tscn` files only when necessary and keep changes minimal
