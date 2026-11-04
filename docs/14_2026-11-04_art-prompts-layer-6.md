# Art prompts: Layer 6 (mobile and release)

**Date:** 2026-11-04

Prompts for Layer 6 art, made with ChatGPT in the same way as [the Layer 1 art](02_2026-11-03_art-prompts-layer-1.md). Attach `art_source/style_reference.png` to the first message of each new chat.

## Tool icons

One image with six icons in a row, because `tools/pixelize.gd` splits a row into frames by the gaps between them. The sword reuses `assets/objects/sword.png`.

Saved as `art_source/ui/tool_icons.png` ✅ done. Shrink with `--height 32 --frame-w 36 --frame-h 32`: the watering can is 34 pixels wide.

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

## UI art (step 3b)

Six images, made in one ChatGPT chat so they match. Send the first prompt with the style reference attached, then each of the others in the same chat.

| Save in `art_source/ui/` as | What |
|---|---|
| `items_row.png` | Radish, carrot, pumpkin, wood, stone, curse shard, coin |
| `items_row_2.png` | Three seed packets, strong holy water |
| `hud_row.png` | Full heart, empty heart, satchel |
| `panel.png` | Menu panel |
| `button.png` | Menu button |
| `round_button.png` | Touch button |

✅ All six are done. Rows are shrunk with `tools/pixelize.gd`, then cut into one file each with `tools/split_row.gd`:

| Row | Height | Frame | Saved as |
|---|---|---|---|
| `items_row.png`, `items_row_2.png` | 24 | 30×24 | `assets/items/` |
| `tool_icons.png`, for the hoe and holy water | 24 | 30×24 | `assets/items/` |
| `hud_row.png`, hearts | 20 | 26×20 | `assets/ui/` |
| `hud_row.png`, satchel | 32 | 40×32 | `assets/ui/bag.png` |

`panel.png`, `button.png` and `round_button.png` use `--scale 8 --single true`, with frames of 64×64, 64×20 and 64×64.

The font is **m5x7 by Daniel Linssen**, CC0, from [managore.itch.io/m5x7](https://managore.itch.io/m5x7), in `assets/fonts/`. It's imported with smoothing off, and used at size 24 (16 for small text, 48 for the title).

### 1. Items

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game. Designed for a 32x32 pixel grid:
chunky, clearly visible pixels, no anti-aliasing, no blur. Moody dark-fantasy style:
muted, desaturated earthy colors, deep purples and teals in the shadows. 3-tone
shading, light from the top-left, neutral daylight (not night, no glow effects).
Transparent background. No text.

A horizontal row of exactly seven small item icons, all the same height, on one line,
with clear empty space between them so none of them touch. From left to right:
1. a harvested radish
2. a harvested carrot
3. a small harvested pumpkin
4. two cut wooden logs
5. a rough grey stone chunk
6. a jagged dark purple crystal shard
7. a worn gold coin
```

### 2. Seeds

```
Now make a second row in exactly the same style, size and spacing, with transparent
background and no text. Exactly four icons, from left to right:
1. a small paper seed packet with a radish picture on it
2. a small paper seed packet with a carrot picture on it
3. a small paper seed packet with a pumpkin picture on it
4. a small corked glass bottle of bright pale-gold water
```

### 3. HUD

```
Now make a third row in exactly the same style, with transparent background and no
text. Exactly three icons, the same height, from left to right:
1. a full deep-red heart
2. the same heart shape, empty, dark grey with a thin outline
3. a small leather satchel with a buckle
```

### 4. Panel

```
Now make a square empty menu panel in exactly the same style: a thick frame of dark
aged wood with small iron corner brackets, around a plain flat very dark brown center
with no pattern. The frame must be the same on all four sides, and the sides must be
plain enough to stretch. It fills the whole image. Transparent outside the frame. No text.
```

### 5. Button

```
Now make a wide empty menu button in exactly the same style: a plain rectangular plaque
of worn wood with a thin darker border and small rounded corners, flat in the middle
so text can sit on it. It fills the whole image. Transparent background. No text.
```

### 6. Touch button

```
Now make an empty round button in exactly the same style: a circle with a worn wooden
and iron rim, and a plain flat dark center so an icon can sit on it. It fills the whole
image, and the circle is perfectly round. Transparent background. No text.
```

## Polish (step 6)

Four images. The **Use** button needs no art: it shows the selected tool's icon. Make the first three in one ChatGPT chat with the style reference attached, the same chat as the UI art if it's still open, so they match the round touch buttons.

| Save in `art_source/` as | What | Replaces |
|---|---|---|
| `ui/touch_icons.png` | Act icon and pause icon, in one row | The words "Act" and "II" |
| `ui/joystick_knob.png` | The joystick's knob | A plain light circle |
| `objects/fence_vertical.png` | A fence running up and down the screen | Side-on fences in a vertical line, which look broken |

Claude shrinks them with `tools/pixelize.gd` when they arrive (measure first; about 24 pixels tall for the icons, 40 for the knob, 32×32 for the fence piece).

### 1. Act and pause icons

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game. Designed for a 32x32 pixel grid:
chunky, clearly visible pixels, no anti-aliasing, no blur. Moody dark-fantasy style:
muted, desaturated earthy colors, deep purples and teals in the shadows. 3-tone
shading, light from the top-left, neutral daylight (not night, no glow effects).
Transparent background. No text.

A horizontal row of exactly two small icons, the same height, on one line, with clear
empty space between them so they don't touch. Simple, bold shapes that read well when
small. From left to right:
1. a hand in a leather work glove with the index finger pointing up, as if reaching to
   open or touch something
2. a pause symbol: two short, thick upright bars of dark iron with worn edges
```

### 2. Joystick knob

```
Now make a joystick knob in exactly the same style: a small round domed knob of worn
wood with a thin iron rim, seen from straight above, slightly lighter in the middle so
it stands out on a dark round base. The circle is perfectly round and fills the whole
image. Transparent background. No text.
```

### 3. Vertical fence

In a **new chat**, attach both `art_source/style_reference.png` and `art_source/objects/fence.png`, so it matches the fence that exists.

```
Match the style of the attached reference exactly, and match the attached fence: the
same wood, colors and thickness.

Pixel art game asset for a 2D top-down farming game, 3/4 top-down view.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Transparent background. No text. Single object, centered, filling most of the image.

The same wooden fence, but running straight up and down the screen, away from the
viewer: one weathered wooden post in the middle, with its two horizontal rails seen
end-on, reaching the top and bottom edges of the art so that sections can stack in a
vertical line.
```
