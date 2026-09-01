"""Lay Tom's caption copy over real app screenshots, full bleed.

Full bleed means the app capture fills the frame and the caption sits in the empty
wall band between the app's own header and the toilet. Nothing is letterboxed and
nothing is re-rendered: the pixels underneath are the actual app.
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

BLACK = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
BOLD  = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

# headline, subhead, source screenshot
SHOTS = [
    ("TIME THE PERFECT FLUSH",   "Hold. Release. Repeat.",                    "1-standard"),
    ("ONE BOWL. ONE SHOT.",      "A new challenge every day.",                "6-daily"),
    ("TEAR. TIME. FLUSH.",       "Swipe the paper. Hit the window.",          "5-paper"),
    ("FROM PORCELAIN TO ORBIT",  "Five fixtures. Five problems.",             "3-orbital"),
    ("KEEP IT CLEAN",            "Plunge when it clogs. Don't let it go.",    "4-upkeep"),
    ("COLLECT LEGENDARY THRONES","Victorian. Orbital. And rarer.",            "2-victorian"),
]

def fit(draw, text, font_path, target_w, start):
    """Largest size that keeps the line inside target_w."""
    size = start
    while size > 12:
        f = ImageFont.truetype(font_path, size)
        if draw.textlength(text, font=f) <= target_w:
            return f
        size -= 2
    return ImageFont.truetype(font_path, 12)

def brightness(im, box):
    crop = im.crop(box).resize((24, 12))
    px = list(crop.getdata())
    return sum(0.299*r + 0.587*g + 0.114*b for r, g, b in px) / len(px)

def compose(src, dst, headline, subhead, band_frac):
    """Grow the room upward, drop the app into the space below, caption the band.

    The app screen has no empty strip to letter over — the header sits directly
    above the cistern — so instead of crowding it, the wall is extended and the
    capture slides down. The only thing lost off the bottom is the on-screen hint,
    which the caption is replacing anyway.
    """
    im = Image.open(src).convert("RGB")
    W, H = im.size

    # Two strips are pure cost in a store shot: the fake status bar at the top and
    # the on-screen hint at the bottom, which the caption is replacing. Dropping
    # both buys the caption its band without pushing the score card off frame.
    top_cut = int(H * band_frac * 0.52)
    bot_cut = int(H * band_frac * 0.48)
    body = im.crop((0, top_cut, W, H - bot_cut))
    band = H - body.height

    swatch = im.crop((0, int(H * 0.10), W, int(H * 0.12))).resize((1, 1)).getpixel((0, 0))
    canvas = Image.new("RGB", (W, H), swatch)
    canvas.paste(body, (0, band))

    # Feather the seam so the join does not read as a hard edge.
    d = ImageDraw.Draw(canvas, "RGBA")
    for i in range(int(H * 0.02)):
        a = int(255 * (1 - i / (H * 0.02)))
        d.line([(0, band + i), (W, band + i)], fill=swatch + (a,))

    light_text = brightness(canvas, (0, 0, W, band)) < 128
    ink = (255, 255, 255) if light_text else (16, 28, 40)

    margin = int(W * 0.055)
    hf = fit(d, headline, BLACK, W - margin * 2, int(H * 0.048))
    sf = fit(d, subhead,  BOLD,  W - margin * 2, int(H * 0.023))
    hh = hf.getbbox(headline)[3] - hf.getbbox(headline)[1]
    sh = sf.getbbox(subhead)[3] - sf.getbbox(subhead)[1]
    gap = int(H * 0.011)

    # Sit the block in the band, biased below the status bar.
    topPad = int(H * 0.012)
    y = topPad + (band - topPad - (hh + gap + sh)) // 2

    for text, font, h in ((headline, hf, hh), (subhead, sf, sh)):
        x = (W - d.textlength(text, font=font)) / 2
        d.text((x, y), text, font=font, fill=ink)
        y += h + gap

    canvas.save(dst, "PNG")
    return canvas.size

root = os.path.expanduser("~/Desktop/FlushSimulator-Screenshots")
out  = os.path.expanduser("~/Desktop/FlushSimulator-Store")
os.makedirs(f"{out}/iphone-6.9", exist_ok=True)
os.makedirs(f"{out}/ipad-13", exist_ok=True)

for i, (head, sub, name) in enumerate(SHOTS, start=1):
    src = f"{root}/iphone-6.9/{name}.png"
    dst = f"{out}/iphone-6.9/{i:02d}-{name.split('-',1)[1]}.png"
    print(f"  iphone {i:02d}-{name}  {compose(src, dst, head, sub, 0.105)}")

# The iPad set is a subset, and its files carry their own numbering.
IPAD = [
    ("TIME THE PERFECT FLUSH",    "Hold. Release. Repeat.",        "1-standard"),
    ("FROM PORCELAIN TO ORBIT",   "Five fixtures. Five problems.", "2-orbital"),
    ("COLLECT LEGENDARY THRONES", "Victorian. Orbital. And rarer.","3-victorian"),
]
for i, (head, sub, name) in enumerate(IPAD, start=1):
    src = f"{root}/ipad-13/{name}.png"
    dst = f"{out}/ipad-13/{i:02d}-{name.split('-',1)[1]}.png"
    print(f"  ipad   {i:02d}-{name}  {compose(src, dst, head, sub, 0.090)}")
