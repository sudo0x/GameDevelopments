# Decisions log

**Date:** 2026-11-04

Choices we made about how the game works, and why, so we don't undo one by accident. If you later ask for something that goes against a decision here (for example, "move the house"), Claude should point to it, explain the reason again, and then do what you decide. A decision can change: when it does, update its row and say why.

Newest first. Bigger plan decisions are also in each plan's "Design decisions" table.

## Playtest session 1 (2026-11-04)

| Question | Decision | Why |
|---|---|---|
| Wide phones: bars, stretch, or show more? | **Show more of the world**, at a whole-number scale | Sharp pixels and a full screen. Phones with different shapes see slightly different amounts of the map, which is fine in a game with no hidden-view challenge |
| Do plants protect land? | **Only ward plants do.** The curse blights food crops, which stop growing but still give 5 money and a curse shard. A watered wardthorn guards land and can burst to heal | The user's idea: a normal plant can't protect itself, unless it's poison to the curse. It also makes the field the player's defense, which other farming games don't have. Blight leaves something behind, because losing a crop outright could make players quit |
| Second curse try: how to add pressure? | **Limit the stall to 3 holy water a day, and grow the curse as land heals** | The first play had no pressure, mainly because money bought unlimited holy water |
| What order after the phone checks? | **Prove it's fun first** (2026-11-07): curse test, simpler controls, first 15 minutes, outside players with sessions 2 to 7, final balance, ads, Google Play, then the woods and marsh. This replaces the order from 2026-11-04 | The biggest unknown is whether players want to come back, and only outside players can show that. Balancing before the core game settles would be wasted work |
| The curse coming back at night: later, or before release? | **Try it before release, as a small test** (2026-11-07), and keep it only if it plays better. This changes the order chosen on 2026-11-04 | The game felt boring after a short time, and sleeping costs nothing. This is the idea most likely to help with both, and it makes the game different from other farming games. See `docs/21_...` |
| Joystick: fixed or moving? | **Moving (Following):** it starts where the thumb lands, and the ring follows a thumb that slides past it | The thumb never has to find it, and there is always room to push. Changed from Dynamic on 2026-11-07, after the thumb went past the ring on a real phone (finding 22) |
| Pause button on phones: where? | **Top right corner** (your choice, after trying it beside the hearts) | The usual spot in mobile games, hard to tap by accident, and it can't be mistaken for part of the health bar. The top right text moves 40 pixels left on phones to make room |
| Watered soil edges: squares, light ragged, or full soft? | **Light ragged**, half as deep as the grass edge | Softer than squares, but each watered tile still shows clearly, which matters for knowing what needs water |
| Tool display on computers? | **A tool bar with icons and number keys**, the same as phones; click to pick | The usual PC farming-game hotbar; reuses the phone's icons, and both layouts now match |
| Aiming felt clumsy: how to help? | **Smart targeting:** tile ahead first, then the tiles beside it if the tool can't use the one ahead; the cursor shows the result. Not for the Hoe and Build | Usual aim assist in phone and console farming games; the cursor makes it predictable, and tools that create things stay exact so they never till or build in the wrong place |
| The first 4 days had nothing to buy: what to do? | **New games start with 2 free holy water** (`start_holy_water`), not starting money | Healing is the game's main reward, so the player should feel it on day 1. Money could go on seeds and miss that moment. The shrine date doesn't change |
| Diagonal facing: new art or code? | **Sticky facing in code:** keep the facing while it's within 60° of the walking direction. No diagonal poses | Diagonal poses need art for 4 more directions, and most farming games don't have them |
| Target highlight: code corners, art cursor, or keep? | **An art cursor** (your choice; Claude had suggested code corners first). Corner brackets only, light so the game tints it red, stretchable for holy water, with a pulse in code. White and red meanings stay | The cursor is what players look at most, so art makes the game feel better. The art requirements keep it to one image that works everywhere |

## Pause menu and messages (2026-11-04, Layer 6 step 6)

| Question | Decision | Why |
|---|---|---|
| What's in the pause menu? | Resume, Settings, Back to title | The three things a player needs mid-game; settings reuse the title's panel |
| What happens to today when leaving? | It's lost, after a question with "No" focused; the game reloads the morning's save | The game only saves when you sleep. Saving mid-day would need far more saved data (positions, watered soil, half-hit trees) |
| Pause on phones? | An "II" button at the top middle, sending Esc's action | Same code path as the keyboard; top middle is the only free spot |
| Messages: stack or queue? | **Queue** on one line: 3 s alone, 1.5 s while others wait, at most 4 waiting | The bottom of the screen has no room for 3 lines (crop status above, tool label below) |
| Use button on phones? | Shows the selected tool's icon | Tells you what Use will do, with no new art |
| The first Act icon (a pointing glove)? | Rejected | A fist with one raised finger can read as a rude gesture when shrunk to 24 pixels |
| The open-glove Act icon? | **Not used. Act shows a "!" in a wooden speech bubble** (chosen 2026-11-04, in the game; prompt in `docs/14_...`). Menus say "Tap ! to close" | It looks almost the same as the Hand tool's glove, so with the Hand tool selected, Use and Act would show two gloves side by side. A different symbol is clearer |
| A vertical line of fences? | The new vertical art at the same pixel scale as the side-on fence: it reads as a line of posts | Squeezing it smaller to show rails would mix two pixel sizes |

## Sound (2026-11-04)

| Question | Decision | Why |
|---|---|---|
| Where are volume settings saved? | Their own file, `settings.cfg` | New Game shouldn't reset your volume, and every farm shares it |
| Sliders or buttons for volume? | − and + buttons, 10% steps | They match the button art, suit thumbs on a phone, and work with keys |
| How are sound files found? | By name, in `assets/audio/effects/` and `music/` | You can add sounds without code changes |
| Sounds before files exist? | Everything wired now, silent until files arrive | Code and sounds can be done separately, in any order |
| Where do the effects come from? | Made by a script (`tools/make_sounds.gd`), from waves | No license, no waiting, matches the retro pixel style. Replace any one later by saving a file with its name |
| Suno gave two versions of the farm music: which one? | **Both:** `farm.mp3` and `farm_2.mp3` play one after another, starting from a random one. Any music can have more versions this way | Claude can't listen to choose, and rotating tracks keeps hours of farming from getting tiring, as farming games usually do. A music choice in settings would be extra work for little gain (it could go in step 6 if wanted). **To drop a version you dislike, delete its file.** Full advice in `docs/18_...`, "Choosing music" |
| Title music? | `title.mp3` from the second Suno prompt, looping. Its second version wasn't downloaded | One version is enough for a screen you see briefly |
| Music? | From the user: a CC0 track, a composer, or a paid AI plan. Claude doesn't generate it, but can make a placeholder drone if asked | A script can make effects well, but not music that stays pleasant on a loop. Full answer in `docs/18_...`, "Can Claude generate the music too?" |
| Which sound matters most? | `cleanse` | The concept says healing must look and sound satisfying |

## Which objects can be moved (2026-11-04)

The Hand tool picks them up and the Build tool places them again, the same as things you build.

| Object | Movable? | Why |
|---|---|---|
| Shipping box | ✅ Yes | You'll want it next to your fields |
| Workbench | ✅ Yes | The same reason: put it where you work |
| The map's 4 lantern posts | ✅ Yes | They're light and safety, so you'll want to choose where they go |
| House | ❌ No | You wake up there and come back there when you faint. Moving it would affect several systems, for little gain |
| Shop stall | ❌ No | It's the island's shop, like a town building. Farming games usually keep shops fixed |

- **The map's lanterns are "Old lantern posts":** they give light and keep creatures away, but don't heal the curse at night, as before. Crafted lantern posts still heal. Making the old ones heal would quietly give 4 free healing lanterns, a balance change nobody has played. Worth revisiting in the balance pass.
- **The Build tool only offers the box, workbench or old lantern while one is in the bag,** since they can't be crafted.

## Soil (2026-11-04)

| Question | Decision | Why |
|---|---|---|
| Can soil be removed? | Yes: the Hoe on empty soil, or 3 nights with no crop | Without it, the farm only ever gets browner. Most farming games do this |
| A fixed count, or random? | A fixed 3 nights, shown when facing the soil | Easier to understand and test |
| Field edges: code or art? | Code, cutting edges from the grass texture | No new art, and it always matches. Hand-drawn transition tiles stay an option if it ever looks wrong |

## Order of work (2026-11-04)

| Question | Decision | Why |
|---|---|---|
| Test on a phone now? | Not yet: play on the computer and report problems, phone in release step 1 (was Layer 6 step 4) | Problems found on the computer can be fixed now |
| Areas or Layer 6 first? | **Layer 6 first**, then the woods and marsh as a free update after release. Order: keep playing, step 5 sound, step 6 polish, step 4 phone, step 7 balance, step 8 ads, step 9 release | Core loop and phone tested before adding content, and release (and income) comes sooner. This replaces the earlier choice of areas before release |
| Where do the rest of Layer 6 and the playing go? | **Layer 6 closes at step 6.** A new **playtest** plan (`docs/19_...`) comes next: play on the computer in sessions, log findings, fix them, and do the balance pass. Then a **release** plan (`docs/20_...`): phone, final balance on the phone, ads, Google Play | The user's idea, and the usual studio order (alpha before release). Claude's two changes, agreed: balance moved into the playtest because it needs playing, and the phone is the release plan's first step, not its last |
