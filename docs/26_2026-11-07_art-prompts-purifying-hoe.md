# Art prompts: purifying hoe and Tasks

**Date:** 2026-11-07

The purifying hoe's icon was the ordinary hoe, only smaller (finding 48). ✅ Its own art is in the game (2026-11-07). It shows in the Bag and the workbench list, at 24×24. The whole hoe lost its cloth and bead at that size, so `tools/build_hoe_icon.gd` keeps only the head.

| File | Game file |
|---|---|
| `art_source/items/purifying_hoe.png` ✅ | `assets/items/purifying_hoe.png`, which the recipe already uses, so no code changes |

The Tasks button's scroll is `art_source/ui/tasks_icon.png` ✅, shrunk with `tools/pixelize.gd --height 30 --frame-w 24 --frame-h 30 --single true` to `assets/ui/tasks_icon.png`. Its prompt is at the end.

Attach `art_source/style_reference.png`, and check the result before using it.

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, 3/4 top-down view.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Transparent background. No text.

One sacred farming hoe, held at a diagonal, with the head at the top left and the
handle running to the bottom right. The blade is pale silver with a clear teal-green
tint, unlike plain iron, and has one small carved rune line down its middle. A
strip of pale cloth is wrapped around the handle just under the blade, tied off
with a small bead of holy water blue. The handle is dark, old wood. The shape must
be simple and easy to read at a very small size, and it must look clearly different
from a plain iron hoe. One object only, centered, with empty space around it.
```

## Tasks icon

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, seen straight on.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Fully transparent background, with no glow or shadow around the object. No text,
no letters, no numbers.

One small old parchment scroll, partly unrolled, with rolled ends at the top and
bottom. Pale warm parchment color, so it stands out on a dark round button. On it,
three short dark horizontal lines stacked like a list, each with a small dark
square to its left, like a checklist. The first square has a small tick in it. The
shape must be simple, bold and easy to read at a very small size. One object only,
centered, filling most of the image, with a little empty space around it.
```

## Build mode's X icon

✅ In the game (2026-11-07), on the `build_mode` button. `art_source/ui/cancel_icon.png` was shrunk with `tools/pixelize.gd --height 39 --frame-w 39 --frame-h 39 --single true`, which shows at exactly 1:1 on a 50-pixel button.

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, seen straight on.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Fully transparent background, with no glow
or shadow around the object. No text, no letters, no numbers.

One bold cancel cross made of two thick crossed pieces of old dark red painted
wood, held together at the center by a small iron nail. The ends are slightly
worn and uneven. Pale edge highlights, so it stands out on a dark round button.
The shape must be simple, bold and easy to read at a very small size. One object
only, centered, filling most of the image, with a little empty space around it.
```
