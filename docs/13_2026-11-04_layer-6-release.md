# Layer 6 plan: mobile and release

**Date:** 2026-11-04

## Goal

Turn the working prototype into a game strangers can install and enjoy on an Android phone. This is the final layer: it adds no big new systems, and instead makes everything built so far playable, understandable and ready for a store.

This layer serves the fourth pillar: **short sessions, long goal.** A player should be able to open the game on a phone, make visible progress in a few minutes, and put it down.

## From prototype to release

```mermaid
flowchart LR
	A[Title menu] --> B[Touch controls]
	B --> C[Phone-sized UI]
	C --> D[Running on a real phone]
	D --> E[Sound and polish]
	E --> F[Balance by real play]
	F --> G[Ads]
	G --> H[Google Play]
	H --> I[Steam later]
```

## Design decisions

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

## In scope

| Feature | Details |
|---|---|
| **Title menu** | Game title, Continue, New Game with a warning. Settings come with sound in step 5, when there's something to set |
| **Touch controls** | Joystick, tool bar, Use and Interact buttons, shown only on touch screens |
| **Phone UI** | Bigger text and buttons, icons for items, and menus that work by tapping |
| **Android build** | An installable game, tested on a real phone |
| **Sound** | Music and effects, especially for healing, the first pillar's reward |
| **Polish** | Queued messages, up-and-down fences, player movement mode, soil edges, moths, grass wind |
| **Balance** | All numbers from Layers 3 to 5, tuned by real play |
| **Rewarded ads** | Faster cleansing or a double harvest, and a Remove Ads purchase |
| **Release** | Store listing, screenshots, privacy policy and AI art disclosure |

## Not in Layer 6

Areas 3 to 6, the cursed heart, the ruined village, new creatures, story, more islands. Those are update ideas for after release.

## Build steps

Each step ends with something you can run and see working.

1. ✅ **Title menu:** Continue, New Game and a working way to start over
2. **Touch controls:** joystick, tool bar and action buttons (needs art)
3. **Phone UI:** readable text, tappable menus, and icons (needs art)
4. **Android build:** the game running on a real phone (needs setup by you)
5. **Sound:** music and effects (needs audio)
6. **Polish:** the weak spots listed in the build notes
7. **Balance pass:** play on a real phone and tune everything (needs you to play)
8. **Rewarded ads:** ads and the Remove Ads purchase (needs accounts)
9. **Google Play release:** closed testing first, then the public store (needs you)

Steam comes after Android, and only needs its own build and store page.

## What only you can do

These can't be done by code, so they're listed early.

| Needed | For | Notes |
|---|---|---|
| **A game title** | Steps 1 and 9 | Still "working title". Worth checking that it's free to use |
| **An Android phone** | Step 4 | With developer mode turned on |
| **A Google Play developer account** | Step 9 | There's a one-time fee, and new personal accounts may need to run a closed test with real testers before a public release. Check Google's current rules when you get there |
| **An ad account** | Step 8 | AdMob is the usual choice, and it needs payment details |
| **A privacy policy** | Steps 8 and 9 | Required once ads collect data |
| **Real playing** | Step 7 | This can't be skipped before release |

## Art and audio needed

| Step | Needed |
|---|---|
| 2 | Tool icons |
| 3 | Item icons: crops, seeds, materials, holy water, coin |
| 5 | Music and sound effects |
| 9 | Store icon, banner and screenshots |

The prompts come with the step that needs them. AI-generated content must be disclosed on Steam, and this project's art docs are the record of how it was made.

## Risks

- **Nothing has been balanced or properly played.** Layers 3 to 5 have only been tested by scripts. Step 7 is required before release, and it may lead to bigger changes than number tweaks.
- **Performance on real phones is unknown.** Everything so far ran on a fast Mac. Lights, particles and creatures need checking on a cheap phone in step 4.
- **Text is small.** The game draws at 640×360, which may be hard to read on a phone. Step 3 might need larger fonts or a different layout.
- **Ad plugins may lag behind Godot.** AdMob needs a plugin that supports Godot 4.7. Check this before step 8, and leave time for it.
- **Old saves must keep working.** `tests/test_old_save.gd` stays in place. New Game must never delete a save without a warning.
- **Windows hasn't been tested lately.** `tests/run_all.sh` has only run on the Mac. Worth checking before building for other platforms.
