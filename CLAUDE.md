# Project guide for Claude

## Start here (every new or reopened chat)

Chats share nothing but this repo, so this file is the handoff. If this chat was open earlier, its memory is out of date: trust this file and git.

1. Run `git pull` and `git status -sb`. Check the machine in your environment, then use its row in "Two dev machines"
2. Run `--headless --import`, then `tests/run_all.sh`, so you know everything works before you change it
3. Read the roadmap below and the plan for the next step, and tell the user in one or two lines where things stand
4. Before changing a part of the code, read its section in [the code map](docs/30_2026-11-09_code-map.md), not the whole file

### Roadmap

Plans have their own step numbers, so **always say which plan you mean**: "animation step 1", "release step 2".

| Order | Work | Plan | Status |
|---|---|---|---|
| 1 | Layers 1 to 6: farming, curse, crafting, building, combat, title, touch, phone UI, art, sound | `docs/03_...` | ✅ Built |
| 2 | Phone checks (release step 1) | `docs/20_...` | ✅ Okay on the user's phone. Remaining checks are in the plan's table |
| 3 | First 15 minutes: story, one goal at a time, Tasks, the old book | `scripts/ui/goal_guide.gd` | ✅ Built. Recheck with outside players |
| 4 | Curse test: the curse takes healed land back at night | decisions log | ✅ **Kept**, played and passed 2026-11-09 |
| 5 | Controls: Farm, Combat and Build modes, bag and storage, combat buttons, six basic weapons, build tools, game icon | `docs/28_...` | ✅ Played and okay on the phone and computer (2026-11-09), on the `storage-prototype` branch. Not merged into `development` yet: ask the user |
| 6 | **Animation:** wind, tall grass that bends as you walk, swaying trees and crops, a living curse, particles, action feedback | `docs/29_...` | **👉 Next: animation step 1** (wind and tall grass; ask for the grass tuft art with its prompt first) |
| 7 | Cleanup: move the older tests off `--classic-controls`, then delete the classic controls' code | `docs/28_...`, "Open" | Waiting. Before the outside test |
| 8 | Outside test: 5 to 10 players who aren't the user | `docs/19_...`, `docs/20_...` | Waiting. Needs the real title and testers. Start the Google Play account before this |
| 9 | Release step 2: final balance on the phone (curse, weapons, prices) | `docs/20_...` | Waiting |
| 10 | Release step 3: rewarded ads | `docs/20_...` | Waiting. Needs an ad account and a privacy policy |
| 11 | Release step 4: Google Play, with the real title and logo | `docs/20_...` | Waiting. Needs a developer account and the real title |
| 12 | Areas steps 1 to 10 (woods, marsh, ending), a free update, only if players stay and want more | `docs/15_...` | Waiting. Before step 1, do its math check on healing a path across 80 more columns |

Each step gets a time limit, so nothing stays almost finished forever. Update this table whenever a step finishes. A ✅ means built and passing tests; say so when it hasn't been played on a phone. Open findings are in `docs/19_...` (**next finding number: 106**); phone-only checks are in `docs/20_...`.

### How we work

The user is usually away from the code, answers with short replies, plays on the computer and on their phone (Redmi Turbo 4 Pro), and reports problems with screenshots.

- **Advise, don't just follow.** If a request isn't the best approach, say so first, suggest the best practice, and let the user choose. The user decides; say plainly when you disagree, but don't keep repeating it
- **Logs:** every problem fixed goes in `docs/16_...` (fixes log, newest first: the problem as the user saw it, the fix, how others solve it); every choice goes in `docs/17_...` (decisions log, with the reason); every finding goes in `docs/19_...`; what was built and why goes in `docs/06_...` (build notes, for learning). Before going against a decision, point to it
- **Keep chats short and cheap:** few tool calls, short replies, don't re-read what's known. Start a new chat after a few steps; this file is the handoff
- One step at a time. At the end, say what changed, what was tested, what wasn't, and what art comes next
- **Commit and push only when asked** ("commit", "commit and build"). Run `tests/run_all.sh` before every commit; after anything random (creatures), run it 3 times. Never call something passing unless it just was
- Look at a screenshot as well as the tests: screenshots catch what tests can't
- Add a test with each feature, and update the plan, the code map and this file in the same step
- **Never touch the user's real save:** tests use a temporary home folder (`APPDATA=<temp>` on Windows, `HOME=<temp>` on Mac), single tests too
- Don't hide a gap behind a ✅ or "later": add it to the findings
- **Art:** the user makes it in ChatGPT/Codex. Any feature that needs a sprite comes with a complete, ready-to-paste prompt (style blocks in `docs/27_...`), and placeholders meanwhile. Check `art_source/` first, since art may already exist. Codex sometimes saves into the project: move its masters to `art_source/`, delete its small copies from `assets/`, and shrink from the master yourself (`docs/27_...`, `tools/pixelize.gd`)
- Use simple English. The user is learning: explain Godot ideas by comparing them to Angular
- Keep changes focused on the request; don't refactor unrelated code
- Open decisions for the user: the game's real title (pick it before the outside test)

## Engine
- Godot 4.7.2, GDScript, Compatibility renderer (web and mobile). Android first, then Steam

## Two dev machines (Windows and Mac)
The user works on both, sometimes in separate chats. Check which one this chat is on (the Platform line in your environment) and use its row.

| | Windows | Mac (Apple Silicon) |
|---|---|---|
| Godot (use `--headless` for checks) | `C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe` | `/Applications/Godot.app/Contents/MacOS/Godot` |
| Art from ChatGPT/Codex | `C:\Users\raksm\.codex\visualizations\...`, `C:\Users\raksm\.codex\generated_images\...`, `C:\Users\raksm\OneDrive\Documents\ChatGPT\GameDevelopment\`, or saved straight into the project (`art_source/generated/`) | `~/Game Assets/`, or `~/.codex/generated_images/<id>/` (drafts sit beside the final image) |
| Save file (not in git) | `%APPDATA%\Godot\app_userdata\Farm Game (working title)\save.cfg` | `~/Library/Application Support/Godot/app_userdata/Farm Game (working title)/save.cfg` |
| `git push` by Claude | Fails: commit, then ask the user to push | Works (`gh` is logged in as `sudo0x`) |

- GitHub is the only link between the machines. `.godot/` isn't in git, so each machine needs `--headless --import`
- `tests/run_all.sh` needs Git Bash on Windows. A full run takes several minutes; run it in the background
- Branches: `development` is the main line; current work is on `storage-prototype`. Remote `sudo0x/GameDevelopments`

## Touch emulation and builds
- The user keeps `[input_devices] pointing/emulate_touch_from_mouse=true` in `project.godot` locally, to see the phone controls on the computer. **Turn it off for tests, builds and commits, and back on after**, and tell the user. Simplest for tests: a temporary `override.cfg` with `[input_devices]` and `pointing/emulate_touch_from_mouse=false`, deleted afterwards
- Phone build: `"<godot>" --headless --path . --export-debug "Android" builds/cursed-island-test.apk` (not in git). The user installs it over the old app, without uninstalling, to keep the phone's save
- Godot may move the `2d/snap/snap_2d_transforms_to_pixel` line in `project.godot`; `git restore project.godot` only after `git diff` shows nothing else

## Game
- Moody dark-fantasy 2D top-down farming game: farming heals a cursed island, and the curse fights back at night (`docs/03_...`)
- One big button does the job of the mode you're in (Farm, Combat, Build); objects are tapped; a limited bag and a storage chest (`docs/28_...`)
- Art: AI pixel art on a 32×32 grid. Lighting: art is neutral daylight; mood comes from `CanvasModulate` and `PointLight2D`, never baked into sprites
- Base resolution 640×360, integer scaling; HUD items must follow an edge, never assume 640×360 (the user's phone shows 924×426)

## Code style
- Static typing everywhere, loops over a literal too (`for side: String in ["left", "right"]`; tests may use `: Variant`), so the code passes with `untyped_declaration` as an error
- snake_case files, variables and functions; PascalCase `class_name` and nodes
- Signals between nodes; no deep `get_node("../../..")` paths. Autoloads only for truly global state
- Tunable numbers live in data files (`data/balance.tres`, `data/crops/`, `data/recipes/`) or one table per feature (`BasicWeapons.STATS`)
- Don't open or edit `.godot/`, binary assets or `.import` files (except `assets/fonts/m5x7.ttf.import`). Prefer `.gd`; keep `.tscn` edits minimal

## Docs
- Index: `docs/README.md`. Name new docs `NN_YYYY-MM-DD_short-name.md` with `**Date:**` under the title, and add them to the index
- Remove finished or outdated plans (git keeps them), recording their result in the decisions log
- Diagrams: ` ```mermaid ` blocks; SVG only for pictures Mermaid can't draw
