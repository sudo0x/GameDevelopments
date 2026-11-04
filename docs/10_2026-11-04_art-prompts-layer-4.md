# Art prompts: Layer 4 (building)

**Date:** 2026-11-04

Prompts for Layer 4 art, made with ChatGPT in the same way as [the Layer 1 art](02_2026-11-03_art-prompts-layer-1.md). Attach `art_source/style_reference.png` to the first message of each new chat.

## Fence

Saved as `art_source/objects/fence.png` ✅ done. The art is 2 posts wide, but a building must fit one tile, so one post with rail on both sides is cut out of it:

`--scale 22.6 --frame-w 32 --frame-h 32 --single true --crop-x 144 --crop-w 723`

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, 3/4 top-down view.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Transparent background. No text. Single object, centered, filling most of the image.

A single short wooden fence section seen from the front: two weathered wooden posts
joined by two horizontal rails, wide and low, with the rails reaching the left and
right edges of the art so that sections can sit side by side.
```

## Well

Saved as `art_source/objects/well.png` ✅ done. Shrink with `--height 64 --frame-w 56 --frame-h 64 --single true`.

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, 3/4 top-down view.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Transparent background. No text. Single object, centered, filling most of the image.

A small old stone well with a round stone wall, a short wooden roof on two posts,
and a wooden bucket hanging from a rope.
```
