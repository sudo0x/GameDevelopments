# Decisions log

**Date:** 2026-11-04

Choices we made about how the game works, and why, so we don't undo one by accident. If you later ask for something that goes against a decision here (for example, "move the house"), Claude should point to it, explain the reason again, and then do what you decide. A decision can change: when it does, update its row and say why.

Newest first. Bigger plan decisions are also in each plan's "Design decisions" table.

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
| Areas or Layer 6 first? | **Still open.** The roadmap says areas first; Claude advised playing first, then finishing Layer 6 and adding the areas as an update | Waiting for your answer |
