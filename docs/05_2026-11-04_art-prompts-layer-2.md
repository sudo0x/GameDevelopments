# Art prompts: Layer 2 (the curse)

**Date:** 2026-11-04

Prompts for Layer 2 art, made with ChatGPT in the same way as [the Layer 1 art](02_2026-11-03_art-prompts-layer-1.md). Attach `art_source/style_reference.png` to the first message of each new chat.

## Old shrine

Two versions of one object, so the second is made in the same ChatGPT chat as the first.

| File | Game size |
|---|---|
| `objects/shrine_cursed.png` ✅ done | 46×80 in a 64×80 frame |
| `objects/shrine_restored.png` ✅ done | 46×80 in a 64×80 frame |

Shrink both with `--height 80 --frame-w 64 --frame-h 80` so they line up when the sprite swaps.

Cursed version:

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, 3/4 top-down view.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Transparent background. No text. Single object, centered, filling most of the image.

A small ancient stone shrine with a carved pillar and a shallow stone basin on top,
standing on a low stone base. It is cursed: dark purple-black stone, thin bright
purple cracks running through it (flat color, no glow effect), and dead vines.
```

Restored version, in the same chat:

```
Now make the exact same shrine, with the same shape, size, angle and layout, but
restored: clean pale grey stone, no purple cracks, fresh green vines and moss, and
clear water in the basin. Same pixel art style, same transparent background, neutral
daylight, no glow effects, no text.
```
