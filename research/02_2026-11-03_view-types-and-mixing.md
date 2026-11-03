# How many 2D views exist, and can one game mix them?

**Date:** 2026-11-03

## How many 2D views are there?

There are **4 main ones**, plus a few variations.

| # | View | Notes |
|---|---|---|
| 1 | **Side view** | Can scroll (follows the player) or stay fixed on one screen |
| 2 | **Top-down** | Two kinds: true overhead (you see only the tops of heads) and **3/4 top-down** (slightly tilted so you see fronts and faces, like Stardew Valley and Pokémon). 3/4 is the most common. |
| 3 | **Isometric** | Diagonal diamond grid that looks like 3D |
| 4 | **Single screen / UI** | Boards, cards, puzzles, menus |

**Less common:**
- **First-person 2D**: you see through the character's eyes as still images (visual novels, point-and-click detective games)
- **2.5D**: made in 3D but played like 2D (side-view movement with 3D graphics)

## Must a game use only one view?

**No.** Many games mix views, but there is **one main view** where players spend most of their time. The others are separate modes or screens.

Examples of mixing:
- **Pokémon**: top-down world, then a front-facing battle screen
- **Classic RPGs (old Final Fantasy)**: top-down world map, then side-view battles
- **Terraria**: side view for gameplay, single-screen UI for inventory and crafting
- **Most games**: the main view plus UI screens (menu, shop, upgrades). Almost every game does this.

**What is hard to mix:** using two views for the **same gameplay**, like switching between side view and top-down while walking around. Gravity, collisions, art and controls all work differently in each view, so you'd basically build two games.

## The cost of each extra view

Each view needs its own:
- **Art**: characters drawn from a different angle
- **Movement code**
- **Level design**

For a solo developer with a 6-month goal, an extra view doubles the work.

## Advice

- **Pick one main view** for the game.
- **UI screens** (menus, shop, upgrade tree) are fine and normal to add.
- **A second gameplay view** (like a battle screen) is only worth it if it's core to the idea. Leave it out of the first game.

**Tip:** in Godot, UI screens are easy with Control nodes. They work much like Angular components.
