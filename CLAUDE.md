# Project guide for Claude

## Start here (every new or reopened chat)

Chats share nothing but this repo, so this file is the handoff. If this chat was open earlier, its memory is out of date: trust this file and git.

1. Run `git pull`. Check the machine in your environment, then use its row in "Two dev machines"
2. Run `--headless --import`, then `tests/run_all.sh`, so you know everything works before you change it
3. Read the roadmap below, then the plan for the next step, and tell the user in one or two lines where things stand

### Roadmap

Two plans have their own step numbers, so **always say which plan you mean**: "areas step 1", or "Layer 6 step 4".

| Order | Work | Plan | Status |
|---|---|---|---|
| 1 | Layers 1 to 5 (farming, curse, crafting, building, combat) | `docs/01`, `04`, `07`, `09`, `11` | ✅ Built. Their balance passes moved to Layer 6 step 7 |
| 2 | Layer 6 steps 1 to 3b (title, touch, phone UI, UI art) | `docs/13_...` | ✅ Built. Title logo waits for the real name |
| 3 | The user plays on the computer and reports problems; fix them between steps | `docs/16_...`, `17_...` | Ongoing |
| 4 | Layer 6 step 5: sound and settings | `docs/13_...`, `18_...` | ✅ Built. 21 effects made by `tools/make_sounds.gd`; farm and title music from Suno (`docs/18_...`) |
| 5 | **Layer 6 step 6: polish.** Part 1 (code) ✅: pause menu with settings, phone pause button, Use shows the tool, queued messages, movable starting objects. Part 2 (art) ✅: pause icon, joystick knob, "!" Act icon, vertical fence | `docs/13_...`, prompts in `14_...` | ✅ Built |
| 6 | **Layer 6 step 4: Android build**, before balance so it's tuned on the real device | `docs/13_...` | **👉 Next.** Needs the user's phone and setup |
| 7 | Layer 6 step 7: balance pass for everything | `docs/13_...` | Waiting. Needs real play, required before release |
| 8 | Layer 6 step 8: rewarded ads | `docs/13_...` | Waiting. Needs an ad account |
| 9 | Layer 6 step 9: Google Play release, with the real title and logo | `docs/13_...` | Waiting. Needs a developer account and the real title |
| 10 | Areas steps 1 to 10 (woods, marsh, ending), as a free update after release | `docs/15_...` | Waiting |

The user chose this order on 2026-11-04: finish and release the smaller game first (see `docs/17_...`). Layer 6 steps are done out of number order, so always name the step. Update this table whenever a step finishes. Everything postponed is in the "Still open" table in `docs/13_...`. A ✅ means built and passing automated tests, not tried on a phone or played by a person.

### How we work

The user is usually away from the code, and answers with short replies.

- **Advise, don't just follow.** If a request isn't the best approach (wrong order, a weaker fix, something that fights the design), say so first, suggest the best-practice way, and let the user choose. Doing exactly what was asked when it's a poor idea isn't helping
- **Every problem fixed goes in `docs/16_...` (fixes log)**, newest first, briefly: the problem as the user saw it, the fix and whether it was code, art, data or a setting, and how other developers often solve it. The user compares fixes to learn. Features still go in the build notes
- **Decisions go in `docs/17_...` (decisions log)**, with the reason. Before doing something that goes against one (for example "move the house"), point to it and explain why, then do what the user decides and update the row
- The user plays on the computer and reports problems with screenshots; testing on a real phone waits for Layer 6 step 4
- One step at a time. At the end of a step, say what changed, what was tested, what wasn't, and what art comes next
- **Commit and push only when asked.** The user normally replies "Commit, start step N", or "Commit and push". "Start step N" alone doesn't mean commit
- Run `tests/run_all.sh` before every commit. After anything random, like creatures, run it 3 times. Report failures honestly, and never call something done or passing unless it just was
- Check the first lines of command output: a failed push or import can scroll past. GitHub sometimes returns a server error, so retry, then compare `git rev-parse HEAD` with `git ls-remote`
- Look at a screenshot as well as the tests. Screenshots have caught what tests couldn't
- Add a test with each feature, and update `docs/06_...` (build notes), the plan's ✅ and this file in the same step
- Never touch the user's real save: tests use a temporary home folder. To check it, copy it to a temporary folder first
- The user decides. Say so plainly when you disagree, but don't keep repeating it: they've chosen not to playtest for now, so mention untested balance only when it matters
- Don't use a ✅ or "later" to hide a gap: if something is left over, add it to "Still open"
- Art prompts by layer: `docs/02`, `05`, `08`, `10`, `12`, `14`. Art files are local until committed, so check `art_source/` before asking for art that may already exist
- Open decisions for the user: the game's real title

## Engine
- Godot 4.7.2, GDScript, Compatibility renderer (for web and mobile)
- Targets Android first, then Steam

## Two dev machines (Windows and Mac)
The user works on both, sometimes in separate Claude chats. Neither one is "old": check which machine this chat is on (the Platform line in your environment) and use that row.

| | Windows | Mac (Apple Silicon) |
|---|---|---|
| Godot (use `--headless` for checks) | `C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe` | `/Applications/Godot.app/Contents/MacOS/Godot` |
| Art files from ChatGPT/Codex | `C:\Users\raksm\.codex\visualizations\<yyyy>\<mm>\<dd>\<id>\` | `~/Game Assets/`, or `~/.codex/generated_images/<id>/` with a random name, where drafts sit beside the final image, so look before copying (one 1254×1254 PNG per image, already transparent; no separate master). Copy into `art_source/` with a clear name |
| Save file (not in git, so each machine has its own farm) | `%APPDATA%\Godot\app_userdata\Farm Game (working title)\save.cfg` | `~/Library/Application Support/Godot/app_userdata/Farm Game (working title)/save.cfg` |
| `git push` by Claude | Fails (the `dancypher` GitHub login is saved) | Works (`gh` is logged in as `sudo0x`) |

- GitHub is the only link between the machines, so unpushed work is invisible on the other one
- `.godot/` isn't in git, so each machine has its own cache: that's why a new session needs `--headless --import`
- `tests/run_all.sh` needs Git Bash on Windows (first passed there on 2026-11-04)
- End of a session: commit, and make sure the work gets pushed before the user switches machines
- Keep both machines on Godot 4.7.2
- Keep this file machine-neutral: when something differs between machines, put it in the table above

## Game
- Moody dark-fantasy 2D top-down farming game: farming heals a cursed island (concept: `docs/03_2026-11-03_game-concept.md`)
- Built in layers: farming → curse/cleansing → collect/craft → build → combat → mobile/release
- What to build next is in the roadmap at the top of this file; read that step's plan before adding features
- Art: AI-generated pixel art on a 32×32 grid; use colored placeholders until an asset exists
- Lighting: art is neutral daylight; mood comes from `CanvasModulate` and `PointLight2D`, never baked into sprites

## Current status (keep this updated at the end of each work session)
- Last updated: 2026-11-04 (after b8176e5: Layer 6 step 6 finished, with the knob, pause and "!" icons and fences that turn)
- **Next:** see the roadmap at the top (Layer 6 step 6). Before areas step 1, after release, do the plan's math check on how long healing a path across 80 more columns takes. Touch has only been simulated, never tried on a phone
- The user has made a game before by following along, and wants to understand the work this time; explain Godot concepts by comparing them to Angular

### How the game works now
- **Player** (`scripts/player/player.gd`, `scenes/player/player.tscn`): 8-way movement, 4 facing poses (`Player.Facing`), feet collision 20×10, `Reach` Area2D. Tools `Player.Tool` (HOE, WATERING_CAN, SEEDS, HAND, HOLY_WATER, BUILD, SWORD) on keys 1–7, Q/E pick a seed (`seed_index` into `GameState.CROPS`), or a building with the Build tool (`building_index` into `GameState.BUILDINGS`). Signals `tool_changed`, `tool_used(tool)`. F calls `interact(player)` on the first overlapping area that has that method
- **Animation**: idle sheet `assets/player/player_idle.png` (4 frames 48×64: down, up, left, right); walk sheets `walk_down/up/side.png` (4 frames, 8 fps, exported on Player; side faces left, right = `flip_h`). A direction without walk art falls back to idle + bob
- **Map**: 76×26 tiles; clean shore (rough ellipse in the west 40×26, must never move: saves store cells by position) surrounded by cursed ground that blocks walking; old farmlands to the east with 3 clean clearings, centers (50, 7), (58, 18), (69, 12), the last for the shrine. The outer ring must stay cursed, because nothing else stops the player leaving the map. `scenes/farm/ground.tscn` is generated by `tools/build_farm_map.gd` (also builds `data/tilesets/ground_tileset.tres`: sources 0 grass, 1 cursed with collision, 2 soil dry, 3 soil wet). Rerunning overwrites hand painting; the tileset is only built if missing, because saving it drops its UID
- **Ground textures** are 128×128 (4×4 tiles); each cell uses the piece at (x mod 4, y mod 4) via `Farm.texture_coords()`
- **Farm** (`scripts/farm/farm.gd`, node `Main/Farm` with Ground, Soil, CurseEdges, Highlight, Healing): any clean grass can be tilled unless a solid object stands on the cell (`is_farmable()`, a physics shape query); target cell = tile in front of the feet; `can_use(tool, cell)` drives the highlight (white = usable, red = not) and `_on_tool_used`. Tilled = a Soil layer cell; watered = SOIL_WET source. `crops: Dictionary[Vector2i, Crop]`, crop nodes go in the y-sorted `World`. Hand tool on a ripe crop calls `harvest(cell)`; the soil stays tilled so the cell can be replanted. The Hoe on empty soil calls `untill(cell)`; soil with no crop for `soil_idle_nights` (3) turns back to grass overnight (`_age_empty_soil()`, counts saved as `soil_idle` in `farm_state`), and facing empty soil says so. `Farm/SoilEdges` draws ragged grass over soil beside grass (`assets/tiles/grass_edge.png`); call `_refresh_soil_edges()` after any soil change
- **Crops**: `CropData` resources in `data/crops/` (radish 3 days, carrot 5, pumpkin 8; seed and sell prices set), listed in `GameState.CROPS`. `Crop` (`scenes/farm/crop.tscn`): `days_grown`, `_stage_for()` (sprout after the first watered night; the last stage only when ripe), `is_ripe()`. Facing a crop shows `Farm.crop_status()` on the HUD's CropStatusLabel, through the `target_status_changed` signal. Frames: radish 32×32, carrot 32×40, pumpkin 40×32 (kept at real pixel size; the sprite offsets by texture height)
- **Days**: house door (`scenes/farm/house.tscn`, Door Area2D) → `GameState.request_sleep()` → HUD fades out → `GameState.end_day()` emits `day_ended` (Farm grows watered crops, dries all soil) then `day_started`
- **Balance**: tunable numbers are in `data/balance.tres` (`GameBalance`), read through `GameState.BALANCE`
- **Cleansing**: `Farm/Healing` (`scripts/farm/healing.gd`) owns everything about healing; Farm calls it as `healing`. `GameState.holy_water` is bought at the stall. `Healing.cleanse(center)` heals the cursed cells in a 3×3 patch, costs one use, and costs nothing if there's nothing to heal; `is_cleansable()` protects the outer ring. The land heals at once; `scenes/farm/cleanse_effect.tscn` (`CleanseEffect.play()`) only draws the old tiles fading out from the center, with a light flash and sparkles, then frees itself. It sizes itself from the cells, so it also suits a large cleanse
- **Shrine**: `scenes/farm/shrine.tscn` (`Shrine`, an Area2D with a StaticBody2D child) at (2224, 412). F emits `activated`; `Healing._on_shrine_activated()` spends `shrine_cost` holy water, sets `restored` (swaps the sprite, turns on its light) and heals a circle of `shrine_radius` through `_cleanse_cells()`. Saved as `shrine` in `farm_state`
- **Curse edges**: `Farm/CurseEdges` (`scripts/farm/curse_edges.gd`, extends `TileEdges` like `SoilEdges`) draws ragged pieces from `assets/tiles/curse_edge.png` over clean tiles beside cursed ones, for looks only; collision still follows the tiles. `refresh(ground)` rebuilds them after any heal, and any new way of changing ground tiles must call it. Rerun `tools/build_curse_edges.gd` (builds both curse and grass edge atlases) then `--import` if `cursed_ground.png` or `grass.png` changes
- **Finds and progress**: `data/buried_finds.tres` (`BuriedFindTable` of `BuriedFind`) places rewards (money, seeds, holy water) on cursed cells, each marked by `scenes/farm/find_glimmer.tscn`. Healing digs them up through `GameState.give_find()`, which sends `notice` to the HUD's NoticeLabel. A find is gone once its cell is in `cleansed`, so finds need no save data. `GameState.healed_percent` comes from `Healing._report_progress()`, shown on the HUD, and isn't saved either
- **Selling**: `scenes/farm/shipping_box.tscn` at (848, 368): F calls `GameState.ship_all()` (all of `harvest` into `shipped`); `end_day()` pays `shipped_value()` before `day_ended`
- **Shop**: `scenes/farm/shop_stall.tscn` at (352, 352): F calls `GameState.request_shop()` → `scenes/ui/shop_menu.tscn` (under HUD; pauses the tree, `process_mode` Always, seed rows built from `GameState.CROPS`, then holy water) → `GameState.buy_seed(crop)` / `buy_holy_water()`
- **Save/load**: `GameState.end_day()` calls `save_game()` last; `_ready()` calls `load_game()`, so the game always resumes in the morning and anything done after the last sleep is lost. File: `user://save.cfg` (ConfigFile, `SAVE_VERSION`; missing, unreadable or other-version files start a new game), written through `save.tmp` and a rename so a crash can't damage it. `tests/fixtures/save_v1.cfg` is a real older save that must keep loading: never regenerate it to pass a test. Farm writes `GameState.farm_state` (cleansed cells, tilled cells, crops) at the end of `_on_day_ended` and rebuilds from it in `_ready`. Not saved: partly hit trees and rocks, player position, watered soil (dry at save time), `shipped` (paid before saving). New Game on the title screen starts over
- **Lighting**: `Main/Mood` CanvasModulate darkens the world (HUD isn't affected, it's a CanvasLayer). `scenes/farm/lantern_post.tscn`: origin at the post's base, `Light` PointLight2D at the lamp (24, -32), radial `GradientTexture2D`, 128px radius. 4 posts in `World` (door, stall, farm south corners). `lantern_light.gd` makes the light flicker
- **GameState** autoload (`scripts/autoload/game_state.gd`): `day`, `money`, `seeds` (start: radish 10, carrot 5, pumpkin 3), `harvest` (`harvest_count()`, `add_harvest()`), `shipped`, signals `inventory_changed`, `sleep_requested`, `shop_requested`, `day_ended`, `day_started`
- **Gathering**: `Farm/Gathering` (`scripts/farm/gathering.gd`) places `Gatherable` objects (`scenes/farm/gatherable.tscn`) in `World` from `data/gather/spots.tres`; kinds are `GatherData` in `data/gather/`. Hand tool on one: 3 hits, then material and remains (a stump is solid, rubble isn't). Ones on cursed land stay hidden until `Healing.land_healed`. They fade while the player is behind them. Gathered ones grow back after `regrow_days` nights (`Gathering.advance_day()`), waiting if the cell is tilled; saved as `gathered` in `farm_state`
- **Buildings**: `BuildingData` in `data/buildings/`, listed in `GameState.BUILDINGS`; crafted ones not yet placed are counted in `GameState.buildings` (saved). `Farm.can_build()` needs clean grass with nothing on it, and its query also sees interact areas and the player. `Farm/BuildPreview` shows the selected building on the target tile, green or red. `Farm/Builder` places them in `World` and saves them as `buildings` in `farm_state` (cell and id). The Hand tool picks placed ones back up. The map's own shipping box, workbench and 4 lantern posts are adopted by `Builder.adopt_starting()` at startup (BuildingData with `starting_only`, which the Build tool skips while none are in the bag; map lanterns are `old_lantern_post`, no healing), so they move the same way; saved as `starting_objects` (names still in place; missing = all stay). House and shop stall are fixed (`docs/17_...`). `GameState.BUILDINGS` is a `var` filled with `load()`, because preloading the box and workbench from GameState is a load loop. A placed building with `heal_radius` above 0 (lantern: 4) heals the nearest cursed tile each night through `Healing.heal_nearest()`. One with `water_radius` above 0 (well: 2, a 5×5 area) waters tilled soil each morning and after loading, in `Farm._water_from_buildings()`
- **Sword**: crafted once (`GameState.has_sword`, saved). `scenes/player/sword.tscn` is a child of Player: `Sword.swing(direction)` sweeps one image through an arc, and mid-swing calls `take_hit(damage, direction)` on anything in its Hitbox with that method. Any new Area2D on the player must also be excluded in `Farm._build_query`
- **Creatures**: `CreatureData` in `data/creatures/`; `Creature` (`scenes/creatures/creature.tscn`) is a CharacterBody2D with states WANDER and CHASE, floated in code, found in `World`. It's on collision layer 2, uses `motion_mode` Floating (the Grounded default made it ride the player like a platform), and finds the player through the `player` group. `_avoid_light()` keeps it `lantern_safe_radius` from anything in the `lantern_light` group (map and placed lanterns). `take_hit()` flashes, knocks back and defeats it; touching calls `Player.hurt()`, which has a 1 second safe time and does nothing while `GameState.day_changing`. `Farm`'s queries use mask 1, so creatures don't block tiles; the sword's Hitbox uses mask 3
- **Spawning**: `Farm/Spawner` (`CreatureSpawner`) clears creatures on `day_ended`, and on `day_started` and load adds `count_for_today()` of them (from `creature_first_day`, more as land heals, capped) on reachable clean cells beside the curse, away from light and the player. `creature_for()` picks hollows from column 52 east, and shades elsewhere. Random but seeded by the day. Tests that sit near the curse's edge past day 3 can be hit, so set `player._safe_left` high there
- **Curse shards**: creatures add their `drop` straight to `materials` when defeated. `GameState.strong_holy_water` is crafted from 1 holy water + 2 shards (`RecipeNeed.holy_water`). Q/E with the Holy water tool toggles `Player.strong_water`, and `Healing.cleanse(center, strong)` heals a 5×5 patch
- **Health**: `GameState.hearts` (not saved, full each morning), `take_damage()`. At 0, `fainted` makes the HUD fade through `_fade_to_next_day()`, end the day, call `Player.return_home()` and show a message. `HeartsBar` draws them in code. `max_hearts` and `faint_money_percent` are in `data/balance.tres`
- **Purifying hoe**: crafted once (`GameState.has_purifying_hoe`, saved). The Hoe tool on a cursed tile calls `Healing.purify()`, which heals that one tile for one of `hoe_uses_left` (from `hoe_daily_uses`, refilled every morning and on load)
- **Crafting**: `scenes/farm/workbench.tscn` at (976, 384): F calls `GameState.request_crafting()` → `scenes/ui/crafting_menu.tscn` (a scrolling list). Recipes are `RecipeData` (with `RecipeNeed`s: a crop or a material) in `data/recipes/`, listed in `GameState.RECIPES`; `GameState.craft()` checks, spends and gives the result
- **Menus**: `GameMenu` (`scripts/ui/game_menu.gd`) is the base for the shop, bag, crafting and pause menus: open, close, pause, `close_action`, and a `_refresh()` to override. They share `data/ui/menu_panel.tres`
- **Materials and bag**: `MaterialData` in `data/materials/`, listed in `GameState.MATERIALS`, counts in `GameState.materials` (saved). `scenes/ui/bag_menu.tscn` on key I shows crops, seeds, holy water and materials; it pauses the game like the shop, and won't open over another menu
- **HUD** (`scripts/ui/hud.gd`): hint line, day and money labels, StatusLabel (top right: holy water, shipping, island healed %), crop status and notice labels, tool/seed label, fade rect. `_refresh()` runs on `inventory_changed`, so emit that when money changes. Notices take turns on one line (`_show_notice()`: 3 s alone, 1.5 s while others wait, max 4 waiting); tests read `hud.latest_notice()` and `hud._waiting_notices`, not the label, since a notice may be waiting
- **Pause menu**: `HUD/PauseMenu` (`scripts/ui/pause_menu.gd`): Esc (`ui_cancel`) opens it when nothing else is open and the day isn't changing; Resume, Settings (`HUD/SettingsMenu`, the title's `SettingsMenu`), Back to title (asks first, then `GameState.discard_unsaved()` reloads the morning's save). Phones get a pause button (iron bars icon) at (320, 22) on the tool bar layer that sends `ui_cancel`; the Use button shows the selected tool's icon, and Act shows a "!" (menus say "Tap ! to close")
- **Touch**: `HUD/TouchControls` (`TouchControls`) shows only where `DisplayServer.is_touchscreen_available()`, or through `set_active(true)`. Godot's built-in `VirtualJoystick` drives the move actions, and `TouchScreenButton`s (built from tables) press normal actions, so game code doesn't know about touch. All help text naming a control goes through `GameState.controls(keyboard, touch)`, and menus set `keyboard_help` and `touch_help`; `tests/test_phone_ui.gd` checks for key names. Menus must not reach the Act button's left edge (x = 501), and a test checks this with a full bag. Tests fake fingers with `InputEventScreenTouch`, using `root.get_final_transform() * position`
- **Theme**: `data/ui/game_theme.tres` is set as `gui/theme/custom` in `project.godot`: m5x7 font at size 24 (keep to 16, 24 or 48), art panels and buttons through `StyleBoxTexture`, and the joystick. Change the look there, not per scene. Icons are `icon` fields on `CropData`, `MaterialData` and `RecipeData`, in `assets/items/`; `GameMenu._icon()` makes a fixed-size picture. On touch screens menus center at x = 39%, to clear Act and Bag
- **Sound**: `Audio` autoload (`scripts/autoload/audio.gd`). `Audio.play(&"name")` for effects (names listed in `Audio.EFFECTS`; a new one must be added there and to `docs/18_...`), `Audio.play_music(&"farm")`. Files are found by name in `assets/audio/effects/<name>.wav|.ogg` and `assets/audio/music/<name>.ogg|.mp3`, with extra versions `<name>_2`, `<name>_3`... played in turn (one version loops); missing ones are silent, `Audio.missing()` lists them. Buses Master, Music, Effects in `default_bus_layout.tres`. Every `BaseButton` gets the `click` sound automatically. Volume saved in `user://settings.cfg` (not the save; New Game keeps it). `SettingsMenu` (`scripts/ui/settings_menu.gd`, built in code, − and + buttons) sits on the title screen; reuse it in the pause menu. Tests check `Audio.last_requested`. With no window (headless, the tests) sounds are picked but not started, because quitting mid-sound leaks. The 21 effects are generated by `tools/make_sounds.gd` (one `sound_<name>()` recipe each; rerun it, then `--import`). Music from Suno: `farm.mp3` and `farm_2.mp3` (alternate), `title.mp3`. Every version plays in turn rather than Claude picking one (`docs/18_...`, "Choosing music"). If the user asks Claude to generate music, point to `docs/18_...` ("Can Claude generate the music too?"): effects yes, music not well, a placeholder drone only if they want one
- **Title**: `scenes/ui/title_screen.tscn` is the first scene (Continue, New Game, Settings, Quit, hidden on phones). New Game asks first if a save exists, with No focused, then calls `GameState.start_new_game()` (deletes the save, then `_reset()`). `_reset()` must reset every saved value: it's also used by `discard_unsaved()`. To add a saved value: add it to `save_game()`, `load_game()` and `_reset()`
- **Main scene**: Main → Farm (Ground instance, Soil, Highlight), Mood, World (y-sorted: House at (912, 288), ShippingBox, ShopStall, 4 lantern posts, Player, crops), HUD (ShopMenu, BagMenu, CraftingMenu, PauseMenu, SettingsMenu, Fade)

### Art
- Done: style reference, player idle + walk ×3, ground ×4, house, radish/carrot/pumpkin stages, shipping box, shop stall, lantern post, shrine (cursed and restored), tree, stump, rock, rubble, workbench, fence (side-on and vertical), well, sword, shade, hollow, tool icons, UI (panel, button, round button, hearts, bag, item icons, pause icon, joystick knob, "!" Act icon)
- Next: none planned until release art (title logo, store icon, screenshots in step 9); later, fence end and corner pieces
- **Workflow**: the user generates art in ChatGPT/Codex; files land in the Codex folder for this machine (see "Two dev machines"). **Always look there first** when the user says art is ready: on Windows search `C:\Users\raksm\.codex\visualizations` recursively by time (`find ... -mmin -90`), since the date folder may not be the one you expect. Sometimes there's a `*-master.png` and a small version, sometimes only one file (2026-11-04). Copy the **master** (on the Mac, the only file) into `art_source/` and shrink with `tools/pixelize.gd`; never use ChatGPT's own small version (it loses detail)
- Find the real pixel size first (measure the color-run length of the master); keep it, don't squeeze art into a tile. Player sheets: `--scale 9.70 --frame-w 48 --frame-h 64`. Ground textures: `--height 128 --frame-w 128 --frame-h 128`. Objects: pick a height that fits next to the player and house rather than the master's pixel size (shipping box `--height 48 --frame-w 40 --frame-h 48`, stall `--height 96 --frame-w 96 --frame-h 96`, lantern `--height 72 --frame-w 48 --frame-h 72`, shrine `--height 80 --frame-w 64 --frame-h 80`, tree `--height 96 --frame-w 96 --frame-h 96`, rock `--height 36 --frame-w 48 --frame-h 40`). Remains use the same `--scale` as the whole object (tree 12.34, rock 23.11). Add `--single true` for art in separate pieces (a pause icon's two bars too), `--crop-x`, `--crop-w` to cut one section from wider art, `--crop-y`, `--crop-h` to cut up and down, and `--circle true` to keep only the circle filling the cut. Each step 6 image's exact command is in `docs/14_...`. Check for faint see-through halos (alpha between 0 and 0.5) when measuring bounds
- Check walk cycles: frames 1 and 3 must lift opposite legs (walk_down needed a fix: frame 3's legs replaced with frame 1's legs mirrored)
- Always give the user complete, ready-to-paste prompts (style block included); never "change this line in the earlier prompt"

### Testing
- **Run `tests/run_all.sh` before every commit** (a few seconds; it uses a temporary home folder, so it never touches the real save, and it fails on any error or warning). Add a test with each new feature: `tests/test_<feature>.gd`, or a `<name>_1_play.gd` and `<name>_2_check.gd` pair for anything that must survive a restart (add pairs to the script). Works on both Mac and Windows
- Headless checks: `--headless --path . --script <test.gd>` with a `SceneTree` script that instantiates `res://scenes/main/main.tscn` and simulates input (`Input.action_press`, or `Input.parse_input_event(InputEventAction)` for `_unhandled_input`). Use `--fixed-fps 60` when timing matters (fades)
- Farm is readied before World, so `player.reach` and other `@onready` values on World's nodes are null in `Farm._ready()`; use `get_node()` there, and guard with `is_node_ready()` in anything Farm calls during setup
- Test scripts can't reference autoloads by name (compiled first); use `root.get_node("GameState")`. This also rules out `class_name`s whose scripts use autoloads (`n is CleanseEffect` fails to compile); check `scene_file_path` instead. A failed test script never quits, so run tests with a time limit
- Screenshots: run without `--headless`, save `root.get_texture().get_image()` after ~30 frames, then look at the PNG
- Run `--headless --import` after adding new images or scripts
- Creatures wander randomly, so a test about them can be flaky: run it several times before trusting it. Tile collision updates on the next physics frame, so wait 2 frames after healing before checking `is_farmable()`
- Tests that call `end_day()` write the save, so run a single test with a temporary home folder too: `HOME=<temp dir>` on Mac, `APPDATA=<temp dir>` on Windows

### Known issues / later
- `project.godot`: Godot itself moves the `2d/snap/snap_2d_transforms_to_pixel` line when it runs; harmless, `git restore project.godot` before committing, **but only after checking `git diff project.godot` shows nothing else**: a real change there (like a new autoload) would be lost
- Quitting the real game while a sound plays prints "ObjectDB instances were leaked" in the console: a harmless Godot cleanup quirk (`docs/16_...`)
- Fences: `Fence.fit()` picks side-on or vertical art from its neighbors (`Builder.fit_neighbors()`, after place, pick up and restore; any building with a `fit()` method gets the same call). Row ends and corners still show a bit of rail sticking out (no end or corner pieces yet)
- Later polish (the user asked, and agreed to wait): moths or butterflies around lanterns, grass moving in the wind
- Standing "facing right" pose is separate art, slightly different from the mirrored walk side

### Git
- Branch `development`, remote `sudo0x/GameDevelopments`. Whether Claude can `git push` depends on the machine (see "Two dev machines"); on Windows, commit, then ask the user to run `git push` themselves

## Display and input
- Base resolution 640×360 (20×11 tiles of 32px), window 1280×720, stretch mode `canvas_items` (not `viewport`: that made movement jump in 2-pixel steps), integer scaling
- Texture filter Nearest, 2D transforms snap to pixel
- Physics interpolation ON (smooth movement on 120 Hz+ monitors with 60 Hz physics); cameras use the physics process callback
- Input actions (in `project.godot`): `move_up/down/left/right`, `tool_1`–`tool_7`, `seed_prev`, `seed_next`, `use_tool`, `interact`, `inventory`

## Folder layout
- `scenes/`: `.tscn` scenes by feature (main/, player/, farm/, ui/)
- `scripts/`: `.gd` scripts mirroring `scenes/`, plus `autoload/`
- `data/`: game data (crop definitions, prices)
- `assets/`: tiles/, crops/, items/, tools/, objects/, player/ (game-ready art at real pixel size, don't read)
- `art_source/`: original AI images from ChatGPT (ignored by Godot via `.gdignore`)
- `tests/`: automated tests and `run_all.sh`, ignored by Godot via `.gdignore`
- `tools/`: dev scripts, ignored by Godot. `build_farm_map.gd` builds the tileset and ground scene. `build_curse_edges.gd` builds the curse edge pieces. `split_row.gd` cuts a sheet into one file per frame. `make_sounds.gd` makes the sound effects from waves. `pixelize.gd` shrinks AI art to real pixel size: `--headless --path . --script tools/pixelize.gd -- --in art_source/... --out assets/... --height 64 --frame-w 48 --frame-h 64`
- `docs/`: design and build plans (ignored by Godot via `.gdignore`); `research/`: research notes

## Code style
- GDScript with static typing (`var speed: float = 200.0`, typed function args/returns)
- snake_case for files, variables and functions; PascalCase for `class_name` and nodes
- Signals for communication between nodes; avoid deep `get_node("../../..")` paths
- Autoloads (singletons) only for truly global state (e.g. `GameState`, `AudioManager`)
- Export tunable values with `@export` so they can be tweaked in the editor

## Docs and research notes
- `docs/16_...` is the fixes log, `docs/17_...` the decisions log (see "How we work"), and `docs/18_...` the sound list (every sound, where it plays, where to get it)
- Name every new doc `NN_YYYY-MM-DD_short-name.md` (next order number in its folder, date created, kebab-case name)
- Put `**Date:** YYYY-MM-DD` right under the title of each doc
- Add each new doc to its folder's `README.md` index (number, date, link)
- Flows, loops, steps, timelines and architecture: use a ` ```mermaid ` block inside the `.md` (GitHub renders it, and it's far cheaper than SVG)
- Only for pictures Mermaid can't draw (game scenes, view styles): SVG in an `images/` subfolder, with hardcoded colors and a white background

## Working rules
- The user won't start art on their own: say exactly which art is needed and when, with complete prompts. Keep coding with placeholders meanwhile
- Use simple English, and say so when you disagree with a choice, instead of only following it
- The user is learning from this project: after each step, add what was built, where and why to `docs/06_2026-11-04_build-notes.md`, and keep its "Things to do better" table honest
- Keep changes focused on the requested feature; don't refactor unrelated code
- Don't open or edit `.godot/` or binary assets, or `.import` files (one exception: `assets/fonts/m5x7.ttf.import` has smoothing turned off)
- Prefer editing `.gd` scripts; edit `.tscn` files only when necessary and keep changes minimal
