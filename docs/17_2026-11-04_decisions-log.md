# Decisions log

**Date:** 2026-11-04

Choices we made about how the game works, and why, so we don't undo one by accident. If you later ask for something that goes against a decision here (for example, "move the house"), Claude should point to it, explain the reason again, and then do what you decide. A decision can change: when it does, update its row and say why.

Newest first. Bigger plan decisions are also in each plan's "Design decisions" table.

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
| Test on a phone now? | Not yet: play on the computer and report problems, phone in Layer 6 step 4 | Problems found on the computer can be fixed now |
| Areas or Layer 6 first? | **Layer 6 first**, then the woods and marsh as a free update after release. Order: keep playing, step 5 sound, step 6 polish, step 4 phone, step 7 balance, step 8 ads, step 9 release | Core loop and phone tested before adding content, and release (and income) comes sooner. This replaces the earlier choice of areas before release |
