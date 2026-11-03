# Pixel art sizes: tiles, sprites and mixing

**Date:** 2026-11-03

## 1. Should we use 32×32 or 64×64?

**Tile size is about how much detail the art has, not how big it looks on screen.** In Godot the camera can zoom: 32×32 art shown at 2× looks the same size as 64×64 art, just with chunkier pixels. So 32×32 does **not** mean a tiny or cramped game.

| | 32×32 | 64×64 |
|---|---|---|
| **Asset packs available** | Many (most top-down farming packs are 16 or 32) | Fewer |
| **Work per sprite** | About 4× less | 4× more pixels to draw or clean up |
| **Animations** (walk, chop, attack) | Much faster | Slow for one person |
| **Cleaning up AI art** | Easier | More pixels to fix |
| **Consistency across all art** | Easier | Harder |
| **Detail** | Clear, classic | More detailed, modern |
| **Readable on phones** | Yes, with camera zoom | Yes |
| **Successful examples** | Many indie hits (Stardew uses even smaller, 16×16) | Fewer solo-dev examples |

**Recommendation: 32×32** (this replaced an earlier 64×64 recommendation):
- Solo developer with a 6-month goal, and art is the least experienced area.
- More asset packs means buying one pack can give a whole consistent world fast.
- The cursed land healing visual (dark turning green) works just as well at 32×32. It comes from color and effects, not pixel count.

Choose **64×64** only if you find a 64×64 asset pack that covers most of what you need, or you plan to hire an artist.

**Practical tip:** search itch.io for "top down farming 32x32" and "top down farming 64x64", and pick the size of the pack whose style you like most. The art you can actually get matters more than the number.

No rush: the gray-box prototype uses colored squares, so this can be decided after it.

## 2. Can we mix 32 and 64 in one game?

Yes, but there are two kinds of "mixing".

### Fine: objects of different sizes, same pixel scale

Almost every pixel art game does this. The **grid is 32×32**, and bigger things use more tiles:

| Thing | Size | In grid tiles |
|---|---|---|
| Ground tile, crop, rock | 32×32 | 1 |
| Player, small enemy | 32×32 or 32×48 | 1 to 1.5 |
| Tree | 32×64 or 64×64 | 2 to 4 |
| House, workshop | 96×96 or 128×96 | 9 to 12 |
| Boss (the cursed heart) | 64×64 or 128×128 | 4 to 16 |

This works because **one pixel is the same size everywhere**. A 64×64 tree just has more pixels, not smaller ones.

### Looks bad: different pixel scales ("mixels")

Art from different detail levels scaled to fit together, e.g. a 64×64 character shrunk into a 32×32 tile, or a 32×32 tree scaled up 2×. Some objects look sharp and detailed, others chunky and blocky. Players notice immediately, and it makes a game look cheap.

> **Rule:** pick **one pixel scale** (32×32 base grid). Objects can be any size, as long as you never resize the art to fit.

When buying asset packs:
- Check that all packs use the **same base size**.
- Don't combine a 64×64 pack with a 32×32 pack. Choose one style.
- In Godot, set the texture filter to **Nearest** so pixels stay crisp, not blurry.

## 3. What does Stardew Valley use?

| Thing | Size in Stardew |
|---|---|
| Ground tiles, crops, small items | **16×16** |
| Characters (player, villagers) | **16×32** (1 tile wide, 2 tiles tall) |
| Trees, buildings | Bigger, spanning several tiles (same pixel scale) |
| Character portraits in dialogue boxes | **64×64** (more detailed) |

On screen the game is zoomed up (each art pixel shows as roughly 4×4 screen pixels).

**Lessons:**
1. **Small tiles can look great.** Style, color and animation matter more than pixel count.
2. **Portraits are the accepted exception** to "one pixel scale". They're UI, not part of the game world, so they can be more detailed.

A 32×32 grid is already twice the detail of Stardew per tile.

## 4. Non-square sizes like 16×32: allowed?

Yes. They're **normal, good, and not hard to code**.

### Two different "sizes"

| | What it is | Shape |
|---|---|---|
| **Tile size (the grid)** | One square of the map: ground, farm plots, where you can build | **Always square**, e.g. 32×32 |
| **Sprite size (the picture)** | One image: player, tree, house | **Any rectangle** that fits the object |

A person is taller than wide, so a tall rectangle fits naturally. Forcing everything to be square would waste space or squash the art.

### Examples for a 32×32 grid

| Thing | Sprite size | Why that shape |
|---|---|---|
| Crop, rock | 32×32 | Fits one tile |
| Player | 32×48 or 32×64 | People are tall |
| Tree | 64×96 | Tall, with a wide top |
| House | 96×96 | Big square building |
| Fence | 32×32 | One tile |

### Is it harder to code? No.

In Godot, the **picture** and the **collision** (what can bump into things) are separate:

- The player's picture might be 32×64 (tall).
- Their collision shape is a **small box at their feet**, about 20×12.
- The head can visually overlap a tree behind them, and only the feet block movement. That's what makes top-down games look right.

Godot's **Y-sort** draws objects lower on the screen in front automatically, so the player walks behind a tree's top and in front of its trunk. It's one checkbox (`y_sort_enabled`), no extra code.

## Summary rule

> **Grid = square** (32×32). **Sprites = any size**, ideally multiples of 16 or 32 so they line up. **Same pixel scale for everything.** UI portraits are the only exception.
