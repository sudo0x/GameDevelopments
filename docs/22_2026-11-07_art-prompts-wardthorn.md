# Art prompts: wardthorn

**Date:** 2026-11-07

Two images for the wardthorn, the plant that is poison to the curse. ✅ Both are in the game (2026-11-07).

The stages were shrunk with `--height 40 --frame-w 32 --frame-h 40 --outline true`, because plain center sampling lost the dark outline. The seed packet image gives the pod. `tools/build_ward_packet.gd` draws that pod on the paper of the other three packets, so all four match.

| File | Game size |
|---|---|
| `art_source/crops/wardthorn_stages.png` ✅ | 4 frames of 32×40, like the carrot, so the ripe plant can stand a little taller |
| `art_source/items/seeds_wardthorn.png` ✅ | About the size of the other seed packets |

## Growth stages

One image with 4 stages in a row, showing only the plant. The soil is a separate tile.

```
Match the style of the attached reference exactly.

Pixel art game asset for a 2D top-down farming game, 3/4 top-down view.
Designed for a 32x32 pixel grid: chunky, clearly visible pixels, no anti-aliasing,
no blur. Moody dark-fantasy style: muted, desaturated earthy colors, deep purples
and teals in the shadows. 3-tone shading, light from the top-left, neutral
daylight (not night, no glow effects). Realistic proportions, not chibi.
Transparent background. No text.

A horizontal row of 4 separate growth stages of one magical plant called a
wardthorn, evenly spaced with clear empty space between them, all standing on the
same baseline, left to right. Draw only the plant, with no soil, pot or ground.

Stage 1: a tiny pale seed bump with one small silver thorn.
Stage 2: a small sprout with two narrow silver-green leaves and tiny thorns.
Stage 3: a young thorny stem with pale silver-green leaves and a closed bud.
Stage 4: a tall ripe thorny plant with a large closed pod at the top. The pod is
pale bone-white with thin warm gold veins, flat color, no glow effect. It looks
sharp and protective, like a plant that is poisonous to dark magic.

Keep it clearly different from the purple curse: use pale silver, bone-white and
warm gold, with only small touches of deep teal in the shadows.
```

## Seed packet

The first packet came back at game size (21×23) with too much detail, so its picture was unclear. Use this prompt instead. Attach `art_source/style_reference.png` and `art_source/items/seeds_pumpkin.png` if it exists, otherwise `assets/items/seeds_pumpkin.png`. Save the **full-size image**, not a small version.

```
Match the style of the attached references exactly.

Pixel art game item icon for a 2D farming game, drawn as a large image with big
chunky pixels. No anti-aliasing, no blur. Moody dark-fantasy style: muted,
desaturated earthy colors. 3-tone shading, light from the top-left, neutral
daylight, no glow effects. Transparent background. No text. Single object,
centered, filling almost the whole image.

A small brown paper seed packet with a folded top, the same shape as the attached
pumpkin seed packet. On the front is ONE very simple, very large picture filling
most of the packet: a single bone-white closed pod with a dark outline and two
bold gold lines on it, on a short dark stem with two sharp thorns. Keep the picture
bold and simple so it stays readable at 24 pixels tall. No leaves, no background
scene, no small details. No words or letters on the packet.
```
