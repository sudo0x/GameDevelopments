# Art prompts: the old book

**Date:** 2026-11-07

Two images that make the book feel old. ✅ Both are in the game (2026-11-07).

The icon was shrunk with `tools/pixelize.gd --height 28 --frame-w 28 --frame-h 28 --single true --outline true`. The page came back soft, with a see-through ring around its middle, so `tools/build_book_page.gd` clears only what's truly outside the torn edge and makes the rest solid. It's used through `data/ui/book_panel.tres`, a 9-slice, so the torn corners keep their shape at any size.

| File | Used for |
|---|---|
| `art_source/ui/book_icon.png` ✅ | The Book button in the Bag, 28×28 in the game |
| `art_source/ui/book_page.png` ✅ | The page behind the book's text, replacing the menu panel |

Attach `art_source/style_reference.png` to both, and check each result before using it.

## Book icon

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, 3/4 top-down view.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Transparent background. No text.

One small closed ancient book, seen at a slight angle. Worn dark brown leather
cover with a simple iron clasp and iron corners. A faint black stain creeps in
from one edge of the cover, as if the curse has touched it. The shape must be
simple and easy to read at a very small size. One object only, centered, with
empty space around it.
```

## Book page

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, seen straight on.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Transparent background. No text, no
writing, no symbols.

One wide rectangular sheet of old dark parchment, in a 3:2 shape, for a game menu.
The middle must be flat and plain, in a dark warm brown, so that pale text can be
read on it. The edges are torn and worn, with black curse stains creeping in from
the corners. Keep all detail within the outer edge, and leave the middle empty.
```
