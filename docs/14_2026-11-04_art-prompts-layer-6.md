# Art prompts: Layer 6 (mobile and release)

**Date:** 2026-11-04

Prompts for Layer 6 art, made with ChatGPT in the same way as [the Layer 1 art](02_2026-11-03_art-prompts-layer-1.md). Attach `art_source/style_reference.png` to the first message of each new chat.

## Tool icons

One image with six icons in a row, because `tools/pixelize.gd` splits a row into frames by the gaps between them. The sword reuses `assets/objects/sword.png`.

Save as `art_source/ui/tool_icons.png`, and shrink with `--height 32 --frame-w 32 --frame-h 32`.

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game. Designed for a 32x32 pixel grid:
chunky, clearly visible pixels, no anti-aliasing, no blur. Moody dark-fantasy style:
muted, desaturated earthy colors, deep purples and teals in the shadows. 3-tone
shading, light from the top-left, neutral daylight (not night, no glow effects).
Transparent background. No text.

A horizontal row of exactly six small tool icons, all the same height, on one line,
with clear empty space between them so none of them touch. From left to right:
1. a farming hoe
2. a metal watering can
3. a small cloth seed pouch
4. an open hand in a leather work glove
5. a small corked glass bottle of clear water
6. a wooden builder's hammer
```
