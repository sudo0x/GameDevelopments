# Art prompts: Layer 3 (gathering and crafting)

**Date:** 2026-11-04

Prompts for Layer 3 art, made with ChatGPT in the same way as [the Layer 1 art](02_2026-11-03_art-prompts-layer-1.md). Attach `art_source/style_reference.png` to the first message of each new chat.

| Source in `art_source/objects/` | Game file in `assets/objects/` | Shrink with |
|---|---|---|
| `dark_green_twisted_tree.png` ✅ | `tree.png` | `--height 96 --frame-w 96 --frame-h 96 --single true` |
| `dark_green_tree_stump.png` ✅ | `tree_stump.png` | `--scale 12.34 --frame-w 96 --frame-h 96 --single true` |
| `rock.png` ✅ | `rock.png` | `--height 36 --frame-w 48 --frame-h 40 --single true` |
| `rock_rubble.png` ✅ | `rock_rubble.png` | `--scale 23.11 --frame-w 48 --frame-h 40 --single true` |
| `workbench.png` ✅ | `workbench.png` | `--height 56 --frame-w 72 --frame-h 56 --single true` |

The remains use the same `--scale` as the whole object, so they stay the same size.

## Tree and stump

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, 3/4 top-down view.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Transparent background. No text. Single object, centered, filling most of the image.

A leafy dark green tree with a twisted brown trunk.
```

In the same chat:

```
Now make the stump left after cutting down this exact tree: the same twisted brown
trunk cut low to the ground, with a pale cut top and no leaves. Same pixel art style,
same transparent background, neutral daylight, no glow effects, no text.
```

## Rock and rubble

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, 3/4 top-down view.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Transparent background. No text. Single object, centered, filling most of the image.

A medium grey rock with rough edges and a little moss.
```

In the same chat:

```
Now make what's left after breaking this exact rock: a few small low grey stones
and chips on the ground, same stone color. Same pixel art style, same transparent
background, neutral daylight, no glow effects, no text.
```

## Workbench

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, 3/4 top-down view.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Transparent background. No text. Single object, centered, filling most of the image.

A sturdy wooden crafting workbench with thick legs, a few simple hand tools on top,
and a small glass bottle of clear water.
```
