# Project guide for Claude

## Engine
- Godot 4.x, GDScript (update the exact version once the project is created)
- Platform: Windows

## Game
- Genre / idea: TODO
- Design doc: `docs/design.md`; read it before adding gameplay features

## Folder layout
- `scenes/`: `.tscn` scenes, grouped by feature (player/, enemies/, ui/, levels/)
- `scripts/`: `.gd` scripts, mirroring `scenes/`
- `assets/`: art, audio, fonts (don't read these, they're binary)
- `docs/`: design notes

## Code style
- GDScript with static typing (`var speed: float = 200.0`, typed function args/returns)
- snake_case for files, variables and functions; PascalCase for `class_name` and nodes
- Signals for communication between nodes; avoid deep `get_node("../../..")` paths
- Autoloads (singletons) only for truly global state (e.g. `GameState`, `AudioManager`)
- Export tunable values with `@export` so they can be tweaked in the editor

## Working rules
- Keep changes focused on the requested feature; don't refactor unrelated code
- Don't open or edit `.godot/`, `.import` files or binary assets
- Prefer editing `.gd` scripts; edit `.tscn` files only when necessary and keep changes minimal
