#!/usr/bin/env python3
"""
Regenerate the blurred wallpaper the greeter cross-fades to.

    python3 make_blur.py [source] [destination] [radius]

Defaults
    source       assets/background.jpg        (next to this script)
    destination  assets/background_blur.jpg
    radius       48

The blurred copy keeps the source's aspect ratio and is capped at 1920px wide,
so it frames exactly like the sharp one (both are cropped to fill the screen).
Requires Pillow:  pip install --user pillow

You normally do not need this — `configure.py` regenerates the blur whenever
you set a new wallpaper. It is here for when you drop a file in by hand.
"""
import os
import sys

try:
    from PIL import Image, ImageFilter
except ImportError:
    sys.exit("Pillow is required: pip install --user pillow")

MAX_W = 1920
here = os.path.dirname(os.path.abspath(__file__))
src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "assets", "background.jpg")
dst = sys.argv[2] if len(sys.argv) > 2 else os.path.join(here, "assets", "background_blur.jpg")
radius = int(sys.argv[3]) if len(sys.argv) > 3 else 48

im = Image.open(src).convert("RGB")
if im.width > MAX_W:
    im.thumbnail((MAX_W, MAX_W * 8), Image.LANCZOS)
im.filter(ImageFilter.GaussianBlur(radius)).save(
    dst, quality=86, optimize=True, progressive=True)
print("wrote %s from %s (radius %d)" % (dst, src, radius))
