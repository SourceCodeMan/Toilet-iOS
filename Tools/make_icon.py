#!/usr/bin/env python3
"""Draws the app icon.

The icon is generated rather than hand-drawn so it can be reviewed as code and
regenerated after a palette change:

    pip install pillow
    python3 Tools/make_icon.py

Output: FlushSimulator/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
"""

import math
import os

from PIL import Image, ImageDraw

SIZE = 1024
SCALE = 4           # supersample, then downsample for clean edges
S = SIZE * SCALE

ROOM_TOP = (176, 226, 235)
ROOM_BOTTOM = (108, 178, 196)
PORCELAIN = (255, 255, 255)
PORCELAIN_MID = (232, 238, 245)
PORCELAIN_DARK = (203, 214, 227)
SHADOW = (88, 112, 136)
WATER_LIGHT = (126, 200, 236)
WATER_DARK = (24, 100, 166)
FOAM = (245, 252, 255)
CHROME_LIGHT = (248, 250, 252)
CHROME_MID = (186, 197, 209)
CHROME_DARK = (108, 120, 134)


def px(value):
    """Icon-space units to supersampled pixels."""
    return value * SCALE


def box(cx, cy, w, h):
    return [px(cx - w / 2), px(cy - h / 2), px(cx + w / 2), px(cy + h / 2)]


def main():
    image = Image.new("RGB", (S, S), ROOM_TOP)
    draw = ImageDraw.Draw(image)

    # Room, top to bottom.
    for y in range(S):
        t = y / (S - 1)
        colour = tuple(round(a + (b - a) * t) for a, b in zip(ROOM_TOP, ROOM_BOTTOM))
        draw.line([(0, y), (S, y)], fill=colour)

    # Tiles.
    grout = (255, 255, 255, 40)
    tile_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    tile_draw = ImageDraw.Draw(tile_layer)
    step = px(128)
    offset = 0
    while offset <= S:
        tile_draw.line([(0, offset), (S, offset)], fill=grout, width=SCALE * 3)
        tile_draw.line([(offset, 0), (offset, S)], fill=grout, width=SCALE * 3)
        offset += step
    image = Image.alpha_composite(image.convert("RGBA"), tile_layer).convert("RGB")
    draw = ImageDraw.Draw(image)

    # Shadow on the floor.
    draw.ellipse(box(512, 892, 660, 90), fill=(96, 150, 170))

    # Cistern and its lid.
    draw.rounded_rectangle(box(512, 348, 430, 350), radius=px(58), fill=PORCELAIN_MID)
    draw.rounded_rectangle(box(512, 340, 430, 350), radius=px(58), fill=PORCELAIN)
    draw.rounded_rectangle(box(512, 175, 476, 74), radius=px(30), fill=PORCELAIN_MID)
    draw.rounded_rectangle(box(512, 170, 476, 74), radius=px(30), fill=PORCELAIN)

    # Bowl: a tapered body under the seat.
    body = [
        (px(250), px(600)),
        (px(774), px(600)),
        (px(690), px(880)),
        (px(334), px(880)),
    ]
    draw.polygon(body, fill=PORCELAIN_DARK)
    draw.polygon(
        [(px(258), px(600)), (px(766), px(600)), (px(684), px(872)), (px(340), px(872))],
        fill=PORCELAIN,
    )
    draw.rounded_rectangle(box(512, 890, 400, 62), radius=px(26), fill=PORCELAIN)

    # Seat.
    draw.ellipse(box(512, 610, 540, 250), fill=PORCELAIN_MID)
    draw.ellipse(box(512, 604, 540, 250), fill=PORCELAIN)

    # The hole, and the water in it.
    draw.ellipse(box(512, 612, 404, 168), fill=SHADOW)
    draw.ellipse(box(512, 616, 388, 152), fill=PORCELAIN_DARK)

    pool = box(512, 620, 344, 126)
    for step_index in range(60):
        t = step_index / 59
        colour = tuple(round(a + (b - a) * t) for a, b in zip(WATER_LIGHT, WATER_DARK))
        top = pool[1] + (pool[3] - pool[1]) * t / 2
        bottom = pool[3] - (pool[3] - pool[1]) * t / 2
        draw.ellipse([pool[0], top, pool[2], bottom], fill=colour)
    draw.ellipse(pool, outline=WATER_DARK, width=SCALE * 2)

    # Swirl.
    cx, cy = px(512), px(620)
    rx, ry = px(172), px(63)
    for arm in range(3):
        points = []
        base = arm * (2 * math.pi / 3)
        for step_index in range(41):
            u = step_index / 40
            theta = base + u * 3.2 * math.pi
            radius = 1 - u * 0.92
            points.append((cx + math.cos(theta) * rx * radius,
                           cy + math.sin(theta) * ry * radius))
        draw.line(points, fill=FOAM, width=SCALE * 9, joint="curve")
    draw.ellipse(box(512, 620, 40, 18), fill=WATER_DARK)

    # Glint on the water.
    draw.ellipse(box(440, 588, 110, 34), fill=(255, 255, 255))

    # Handle, on the tank face rather than hanging off its edge.
    #
    # The cistern spans x 297..727. The lever used to run 140..296, which put the
    # whole thing outside the tank in mid-air. ToiletView mounts it inboard: a
    # 58x15 capsule from the cistern's left edge to a pivot 58 units in, tilted 10
    # degrees so the free end hangs low. In icon units that is 297..422 at y 270.
    lever = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    lever_draw = ImageDraw.Draw(lever)
    lever_draw.rounded_rectangle(
        [px(297), px(253), px(424), px(287)], radius=px(17), fill=CHROME_LIGHT
    )
    lever_draw.rounded_rectangle(
        [px(297), px(275), px(424), px(287)], radius=px(6), fill=CHROME_MID
    )
    # Negative because Pillow rotates counter-clockwise and the app tilts the other way.
    lever = lever.rotate(-10, resample=Image.BICUBIC, center=(px(422), px(270)))
    image = Image.alpha_composite(image.convert("RGBA"), lever).convert("RGB")
    draw = ImageDraw.Draw(image)

    draw.ellipse(box(422, 270, 60, 60), fill=CHROME_MID)
    draw.ellipse(box(422, 270, 52, 52), fill=CHROME_LIGHT)
    draw.ellipse(box(422, 270, 14, 14), fill=CHROME_DARK)

    icon = image.resize((SIZE, SIZE), Image.LANCZOS)
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    destination = os.path.join(
        here, "FlushSimulator", "Assets.xcassets", "AppIcon.appiconset", "AppIcon-1024.png"
    )
    icon.save(destination, "PNG")          # RGB, no alpha: App Store icons must be opaque
    print("wrote", destination)


if __name__ == "__main__":
    main()
