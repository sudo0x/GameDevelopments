# Decisions log

**Date:** 2026-11-04

Choices we made about how the game works, and why, so we don't undo one by accident. If you later ask for something that goes against a decision here (for example, "move the house"), Claude should point to it, explain the reason again, and then do what you decide. A decision can change: when it does, update its row and say why.

Newest first. The first choices from the finished layer plans are at the end.

## Playtest session 1 (2026-11-04)

| Question | Decision | Why |
|---|---|---|
| What shows a crop is ripe? | **The crop itself, with no star** (2026-11-07, the user's choice). Only the water drop remains as an icon | Fewer icons keep the field calm, and they'd get in the way of animation later |
| Does a wardthorn seed guard? | **Only its own tile, until it sprouts** (2026-11-07, the user's catch) | A seed protecting land the moment it's planted isn't logical, and it let planting save tonight's marks. Now guarding takes planning ahead |
| What does a wardthorn guard? | **Once sprouted: 3×3 dry, 7×7 watered, and 5×5 ripe with no water, until burst** (2026-11-07, from the user's idea, sizes by Claude) | A growing one should always do something. Ripe gives a real choice: keep a free guard, or burst to heal. It stays below watered size, so daily care still pays |
| How many docs do we keep? | **Only what's used to build and plan the game** (2026-11-07, the user's choice). Finished plans and old art prompts were removed, and their design reasons moved here | Fewer, current docs are easier to trust. Git history keeps the rest |
| What do lanterns and wardthorn each do? | **Lanterns are rare and permanent, wardthorn is cheap and needs care** (2026-11-07, Claude's design at the user's request) | Lanterns beat wardthorn at everything, so spamming them was the best plan and made the land messy. Now a lantern guards 5×5, must stand 6 tiles from another and costs curse shards. A wardthorn guards 7×7 while watered |
| What limits farm size? | **Water, not soil** (2026-11-07, Claude's design at the user's request). The can holds 10, is full each morning and refills at wells | Energy bars just stop people playing. Water makes field size and well placement a choice, and gives wells a job |
| Is the starting well movable? | **No, it's fixed like the house** (2026-11-07) | Saves list which map objects are still in place, so a new movable one would be removed from older saves. Loading clears any soil or crop under it |
| How do popups grow with more items? | **`PickMenu` scrolls now. The Bag gets tabs just before the areas work** (2026-11-07) | Scrolling is small and fixes Seed and Build together. Tabs are a bigger job, and aren't needed until there's more to list |
| Does the goal stay on the screen? | **No: a Tasks menu holds goals, and a new one shows for 6 seconds** (2026-11-07, the user's choice). This adds a small sixth button | A clear screen, and the user can read as much as they want. Claude advised keeping one line, so new players always know what's next: the fading line covers that, and the outside test will check it |
| Who runs the shop and buys from the box? | **A night trader nobody has seen** (2026-11-07, the user's choice) | One book page explains the box, the stall and its limit of 3 holy water, with no new systems, and keeps the island lonely |
| How many free heals does the purifying hoe give? | **2 a day, down from 5** (2026-11-07, the user's catch) | 5 beat the curse's 3 to 5 tiles a night, so one cheap tool made holy water, lanterns and wardthorn optional early on. At 2 it helps, but can't win alone |
| How should Build work on phones? | **Pick from a list of what you own, then the big button places it, with an X to leave** (2026-11-07, after the user disliked the hammer and arrows) | It works like the Seed popup, never shows something you can't place, and ends by itself when you run out |
| Should a tap on a tile farm it? | **No** (2026-11-07, the user's choice). The character walks there and the big button does the work. Holding a building to move it stays | The user felt it was wrong with a walking character, and that's right: tapping would make the character stand idle, and walking into the curse is part of the game. Moving buildings is arranging the farm, not the character's work |
| What comes after the controls phone test? | **Moving objects by press and hold, then the ancient book, both built during the phone test at the user's request. A quest board waits for the outside test** (2026-11-07, the user's choice) | Moving objects is small and part of the controls. The book adds story with little risk. A board is a new system with balance work, so it needs proof that players want it |
| Do book pages go away if the curse takes land back? | **No, a found page stays** (2026-11-07) | Losing story you already read would feel like a bug, not a danger. It costs one saved number |
| What happens to strong holy water and Build without the tool bar? | **Heal asks which water, but only if you own both. A small hammer starts Build mode until step 5** (2026-11-07, controls step 4) | The plan missed that both needed the arrows. Asking costs a tap, but only for a limited item. Each step must stay playable |
| Action button, tapping tiles, or Hay Day style? | **Keep the Action button** (2026-11-07, the user's choice after playing). Tapping nearby tiles is the fallback if outside players struggle. See `docs/24_...` | It felt strange at first, then good after more play. Hay Day has no walking character, so copying it would mean rebuilding walking, combat and the camera |
| How do phones use the purifying hoe? | **The Heal button**, on one cursed tile, before holy water (2026-11-07, the user's choice) | The tool bar goes in controls step 4, and healing is what the hoe is for. Free daily uses go first, so holy water isn't spent while they last |
| Does Use go in controls step 3, as planned? | **Not yet** (2026-11-07). It moves to Act's old spot, and goes in step 5 | Holy water, Build and the purifying hoe still need it. The plan says every step stays playable, and removing it early would mean throwaway code to reach them |
| Should the Action button sleep at once at the door? | **No, it asks "Sleep?" first** (2026-11-07, the user's choice, on Claude's advice) | Action does many jobs, so a tap beside the house could be meant for something else, and sleeping can't be undone. It would lose the rest of the day |
| Do objects with nothing to do block the Action button? | **No** (2026-11-07, controls step 2). An empty box or a restored shrine is skipped, so the tile in front decides. F still reaches them | The chart says the box comes first, but a box you can't use would stop you tilling beside it for nothing, and the button would promise an action that does nothing |
| Does `GameState` disappear in the split? | **No, a small one stays** (2026-11-07, controls step 1), with `BALANCE`, `notice`, `controls()` and the menu requests | The plan named three parts, but these fit none of them: they aren't owned items, progress or saving. Forcing them in would make each part a bit of a junk drawer |
| Wide phones: bars, stretch, or show more? | **Show more of the world**, at a whole-number scale | Sharp pixels and a full screen. Phones with different shapes see slightly different amounts of the map, which is fine in a game with no hidden-view challenge |
| Simpler controls or the curse play test first? | **Simpler controls first** (2026-11-07, the user's choice), then play both together | Claude advised playing first, because the result could change which tools stay. The user prefers to play the game with its final controls, and any tool change is small to fix later |
| How does a new player learn the game? | **A short story on New Game, then one goal at a time, then the long goal.** Built before simpler controls, which changes the 2026-11-07 order | Long tutorials get skipped, so players learn by doing. The curse test needs a New Game, so the start had to make sense first. The goals are data, so they're cheap to update when the buttons change |
| Do plants protect land? | **Only ward plants do.** The curse blights food crops, which stop growing but still give 5 money and a curse shard. A watered wardthorn guards land and can burst to heal | The user's idea: a normal plant can't protect itself, unless it's poison to the curse. It also makes the field the player's defense, which other farming games don't have. Blight leaves something behind, because losing a crop outright could make players quit |
| Second curse try: how to add pressure? | **Limit the stall to 3 holy water a day, and grow the curse as land heals** | The first play had no pressure, mainly because money bought unlimited holy water |
| What order after the phone checks? | **Prove it's fun first** (2026-11-07): curse test, simpler controls, first 15 minutes, outside players with sessions 2 to 7, final balance, ads, Google Play, then the woods and marsh. This replaces the order from 2026-11-04 | The biggest unknown is whether players want to come back, and only outside players can show that. Balancing before the core game settles would be wasted work |
| The curse coming back at night: later, or before release? | **Try it before release, as a small test** (2026-11-07), and keep it only if it plays better. This changes the order chosen on 2026-11-04 | The game felt boring after a short time, and sleeping costs nothing. This is the idea most likely to help with both, and it makes the game different from other farming games. See `docs/21_...` |
| Joystick: fixed or moving? | **Moving:** it starts where the thumb lands, the ring follows a thumb that slides past it, and it stays in a safe area | The thumb never has to find it, and there is always room to push. Changed on 2026-11-07 after phone play (findings 22 and 35). It's now our own `ThumbStick`, because Godot's can't limit where its ring goes |
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
| The open-glove Act icon? | **Not used. Act shows a "!" in a wooden speech bubble** (chosen 2026-11-04, in the game). Menus say "Tap ! to close" | It looks almost the same as the Hand tool's glove, so with the Hand tool selected, Use and Act would show two gloves side by side. A different symbol is clearer |
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

## From the finished layer plans

Moved here when those plans were removed. These are the first choices, so a newer row above wins where they differ, and `data/` holds the real numbers.

### The curse (Layer 2)

| Question | Decision | Why |
|---|---|---|
| How does the player cleanse before crafting exists? | Buy **holy water** at the stall | Links farming to cleansing now. Layer 3 can add crafting without changing how cleansing works |
| How much does one use clean? | A **3×3 patch** around the target tile, for about 30 money | One tile at a time would feel slow, and a big patch turning green looks better |
| Where can the player farm? | **Any clean grass**, instead of a fixed farm area | Cleansing should pay off straight away |
| Does the curse fight back? | **No, not in this layer** | Keeps the layer small. Creeping curse stays an update idea, and lantern protection comes with it |
| What's the goal of the layer? | Reach and restore the **old shrine** in the old farmlands | Gives the player somewhere to head, and a big moment at the end |

Prices are starting values, to be tuned once the loop can be played.

### Gathering and crafting (Layer 3)

| Question | Decision | Why |
|---|---|---|
| How does the player gather? | With the **hand tool** (key 4), a few hits per tree or rock | No new tools to switch between, which also keeps touch controls simple later |
| Where do trees and rocks grow? | Placed around the map, including on cursed land | Reachable only after healing, so "cleansed land reveals resources" needs no extra code |
| Do they run out? | **Regrow** after a few days | The player can't get stuck with no materials |
| Where does crafting happen? | A **workbench** near the house, with a menu like the shop | Reuses a pattern that already works |
| Does the shop keep selling holy water? | **Yes**, but crafting it is cheaper | Crafting is a reward, not a wall |
| What does the purifying hoe do? | Heals **one tile for free, 5 times a day** | Steady free healing without making holy water pointless |
| Where's the inventory shown? | A new panel on a key, with only key numbers left on the HUD | The HUD's top-right list is already 6 lines long |

Recipes and amounts are starting values, to be tuned once the loop can be played.

| Recipe | Needs | Makes |
|---|---|---|
| Holy water | 1 radish, 1 stone | 1 holy water |
| Purifying hoe | 10 wood, 5 stone | The hoe, once only |

### Building (Layer 4)

| Question | Decision | Why |
|---|---|---|
| Where can the player build? | **Clean grass only**, with nothing solid on it | Matches the concept's rule, and pushes the player to heal more |
| How do you get buildings? | **Craft them at the workbench**, then place them from the bag | Reuses recipes, so a building is only new data |
| How do you place one? | A **Build tool on key 6**: Q and E pick the building, Space places it | Works like the Seeds tool, which the player already knows |
| How do you see where it goes? | A see-through **preview**, tinted red if it can't go there | The player should never have to guess |
| Can you take one back? | **Yes**, with the hand tool, and you get it back | Mistakes shouldn't cost anything |
| What makes a lantern useful? | It **heals one nearby cursed tile each night** | Turns the warm-light look into a real mechanic, as the concept asks |
| Does the curse fight back? | **Still no** | Keeps this layer small. Enemies arrive in Layer 5 |

Recipes and numbers are starting values, kept in data files so they're easy to tune.

| Building | Needs | Does |
|---|---|---|
| Lantern post | 3 wood, 2 stone | Gives warm light and heals 1 nearby cursed tile each night |
| Fence | 1 wood | Decoration, and blocks walking |
| Well | 5 wood, 8 stone | Waters every crop in a 5×5 area each morning |

### Combat (Layer 5)

| Question | Decision | Why |
|---|---|---|
| Where do creatures come from? | They **rise from the curse's edge** each morning, on land near it | Players can't walk on cursed land, so creatures have to come to them |
| What keeps the farm safe? | Creatures **can't enter lantern light** | Turns the concept's rule into the main way to defend your land, and makes placing lanterns a real choice |
| How does the player fight? | Craft a **sword**, used on key 7 with Space, hitting in front of the player | Works like every other tool, and maps to one button on a phone |
| What's the health system? | **5 hearts**, refilled by sleeping | Simple to read and fits the existing day loop |
| What happens at 0 hearts? | You **faint and wake at home** the next morning, losing a little money | Short sessions shouldn't end in a harsh punishment, and nothing else is lost |
| Are creatures saved? | **No.** They vanish at night and new ones rise each morning | Keeps saves simple, and every morning is a fresh start |
| Do they get stronger? | A **tougher creature** appears further east | Matches "stronger toward the center" from the concept |
| What do they drop? | **Curse shards**, a new material | Gives fighting a purpose tied to healing |

Numbers are starting values, kept in data files so they're easy to tune.

| Creature | Hearts of damage | Hits to defeat | Where |
|---|---|---|---|
| Shade | 1 | 2 | Along the curse's edge |
| Hollow | 2 | 4 | The far east of the old farmlands |

| Recipe | Needs | Makes |
|---|---|---|
| Sword | 5 wood, 3 stone | The sword, once only |
| Strong holy water | 1 holy water, 2 curse shards | Heals a 5×5 patch |

### Phones and release (Layer 6)

| Question | Decision | Why |
|---|---|---|
| How do you move on a phone? | A **virtual joystick**, on the left | It's familiar, and it feeds the existing movement actions |
| How do you pick tools? | A **tool bar** of icons along the bottom | Seven keyboard keys need a touch version, and it also replaces the tool text |
| How do you act? | **Use** and **Interact** buttons, on the right | Matches Space and F, so game code barely changes |
| Do keyboards keep working? | **Yes** | Needed for Steam, and it keeps the tests valid |
| How do players start over? | A **title menu** with Continue and New Game | Deleting a file isn't acceptable for real players |
| When does the game save on a phone? | **Still each morning**, plus a warning that progress saves when you sleep | Phones close apps without asking, so players must know the rule |
| How do ads work? | **Rewarded only**: the player chooses to watch one, as the concept planned | Forced ads would break the mood |
| Which store comes first? | **Google Play**, then Steam | Matches the project's plan |
