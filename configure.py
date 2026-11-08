#!/usr/bin/env python3
"""
configure.py — wallpaper and profile picture for the Lyne-sddm greeter.

Prompts for a path, copies the image into the theme's assets/ folder in the
format the theme expects, regenerates the blurred wallpaper from it, and points
theme.conf at the result. Run it again at any time to change either one.

    python3 configure.py                  # asks for both
    python3 configure.py --wallpaper ~/wall.png
    python3 configure.py --theme /usr/share/sddm/themes/Lyne-sddm

Press Enter at a prompt to keep what is already there.
"""
import argparse
import colorsys
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter
except ImportError:
    sys.exit(
        "Pillow is required to process images.\n"
        "  Arch:   sudo pacman -S python-pillow\n"
        "  Debian: sudo apt install python3-pil\n"
        "  other:  pip install --user pillow"
    )

WALL_MAX, WALL_QUALITY = 3840, 88
BLUR_MAX, BLUR_RADIUS, BLUR_QUALITY = 1920, 48, 86
AVATAR_MAX = 512

WALL_NAME = "assets/background.jpg"
BLUR_NAME = "assets/background_blur.jpg"
AVATAR_NAME = "assets/avatar.png"


# ---------------------------------------------------------------- helpers ---

def clean_path(raw):
    """Turn whatever was pasted (quotes, ~, $VARS, relative) into a Path."""
    s = raw.strip().strip("'\"")
    s = os.path.expandvars(os.path.expanduser(s))
    return Path(s).expanduser().resolve()


def looks_like_image(path):
    try:
        with Image.open(path) as im:
            im.verify()
        return True, ""
    except Exception as exc:  # noqa: BLE001 - we only want the message
        return False, str(exc)


def ask(prompt):
    """Ask until we get a usable image, or an empty answer to skip."""
    while True:
        try:
            raw = input(prompt)
        except (EOFError, KeyboardInterrupt):
            print()
            return None
        if not raw.strip():
            return None
        p = clean_path(raw)
        if not p.exists():
            print("    no such file: %s" % p)
            continue
        if p.is_dir():
            print("    that is a folder, not an image")
            continue
        if not os.access(p, os.R_OK):
            print("    not readable: %s" % p)
            continue
        ok, why = looks_like_image(p)
        if not ok:
            print("    that does not look like an image (%s)" % why)
            continue
        return p


def place(tmp_path, dest_path):
    """Copy a finished file into the theme, using sudo only if we must."""
    dest = Path(dest_path)
    parent = dest.parent
    if os.access(str(parent), os.W_OK):
        shutil.copyfile(tmp_path, dest)
    else:
        subprocess.run(["sudo", "mkdir", "-p", str(parent)], check=True)
        subprocess.run(["sudo", "cp", str(tmp_path), str(dest)], check=True)


def update_conf(theme_dir, values):
    """Rewrite just the given keys in theme.conf, leaving the rest alone."""
    conf = Path(theme_dir) / "theme.conf"
    text = conf.read_text()
    for key, val in values.items():
        line = '%s="%s"' % (key, val)
        pattern = re.compile(r"^%s\s*=.*$" % re.escape(key), re.MULTILINE)
        if pattern.search(text):
            text = pattern.sub(lambda _m: line, text, count=1)
        else:
            text = text.rstrip("\n") + "\n" + line + "\n"
    fd, tmp = tempfile.mkstemp(suffix=".conf")
    with os.fdopen(fd, "w") as fh:
        fh.write(text)
    place(tmp, conf)
    os.unlink(tmp)


# ----------------------------------------------------------- image work ---

def _dominant_hue(im):
    """Hue and saturation of the most prominent colourful part of an image."""
    small = im.resize((80, 80), Image.LANCZOS)
    q = small.quantize(colors=16, method=Image.MEDIANCUT).convert("RGB")
    pixels = list(q.getdata())
    counts = Counter(pixels)
    total = float(len(pixels))

    best_hsv, best_score = None, -1.0
    for rgb, n in counts.items():
        h, s, v = colorsys.rgb_to_hsv(rgb[0] / 255.0, rgb[1] / 255.0, rgb[2] / 255.0)
        if v < 0.08 or v > 0.97:            # skip near-black and near-white
            continue
        score = (n / total) * (s ** 1.5) * (0.30 + 0.70 * min(1.0, v * 1.7))
        if score > best_score:
            best_hsv, best_score = (h, s, v), score

    if best_hsv is None:                    # nothing colourful: just average it
        avg = tuple(sum(c) / total for c in zip(*pixels))
        h, s, _v = colorsys.rgb_to_hsv(avg[0] / 255.0, avg[1] / 255.0, avg[2] / 255.0)
        return h, s
    return best_hsv[0], best_hsv[1]


def extract_colors(path):
    """(pill tint, accent) taken from the wallpaper's dominant colour."""
    h, s = _dominant_hue(Image.open(path).convert("RGB"))

    # a grey wallpaper has no meaningful hue: stay neutral rather than
    # inventing a colour (hue 0 would come out red)
    if s < 0.10:
        return "#191a1d", "#e8e9ee"

    # deep tint for the frosted pills - always dark enough for white text
    tr, tg, tb = colorsys.hsv_to_rgb(h, min(0.55, s * 0.85), 0.13)
    # brighter version for borders, hover and the focused password field
    ar, ag, ab = colorsys.hsv_to_rgb(h, min(0.85, max(0.45, s)), 0.92)

    return ("#%02x%02x%02x" % (round(tr * 255), round(tg * 255), round(tb * 255)),
            "#%02x%02x%02x" % (round(ar * 255), round(ag * 255), round(ab * 255)))


def build_wallpaper(src, out):
    im = Image.open(src).convert("RGB")
    if max(im.size) > WALL_MAX:
        im.thumbnail((WALL_MAX, WALL_MAX), Image.LANCZOS)
    im.save(out, "JPEG", quality=WALL_QUALITY, optimize=True, progressive=True)


def build_blur(wall_path, out):
    """Same aspect ratio as the wallpaper, so the cross-fade lines up."""
    im = Image.open(wall_path).convert("RGB")
    if im.width > BLUR_MAX:
        im.thumbnail((BLUR_MAX, BLUR_MAX * 8), Image.LANCZOS)
    im = im.filter(ImageFilter.GaussianBlur(BLUR_RADIUS))
    im.save(out, "JPEG", quality=BLUR_QUALITY, optimize=True, progressive=True)


def build_avatar(src, out):
    """Centre-crop to a square and knock the corners off, so the greeter can
    draw it as a circle without needing a mask effect at runtime."""
    im = Image.open(src)
    if im.mode not in ("RGB", "RGBA"):
        im = im.convert("RGBA")

    side = min(im.size)
    left = (im.width - side) // 2
    top = (im.height - side) // 2
    im = im.crop((left, top, left + side, top + side))
    if side > AVATAR_MAX:
        im = im.resize((AVATAR_MAX, AVATAR_MAX), Image.LANCZOS)
        side = AVATAR_MAX
    im = im.convert("RGBA")

    # draw the mask at 4x and scale it down so the circle edge is smooth
    big = side * 4
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, big - 1, big - 1), fill=255)
    mask = mask.resize((side, side), Image.LANCZOS)

    im.putalpha(mask)
    im.save(out, "PNG", optimize=True)


# ------------------------------------------------------------------ main ---

def main():
    ap = argparse.ArgumentParser(
        description="Set the wallpaper and profile picture for the Lyne-sddm theme.")
    ap.add_argument("--theme", default=os.path.dirname(os.path.abspath(__file__)),
                    help="theme folder (default: the folder this script is in)")
    ap.add_argument("--wallpaper", help="wallpaper image; skips that prompt")
    ap.add_argument("--avatar", help="profile picture; skips that prompt")
    ap.add_argument("--no-tip", action="store_true", help=argparse.SUPPRESS)
    args = ap.parse_args()

    theme = Path(args.theme).resolve()
    if not (theme / "theme.conf").exists():
        sys.exit("No theme.conf in %s — is that the theme folder?" % theme)

    print()
    print("Lyne-sddm — wallpaper & profile picture")
    print("=" * 42)

    # ---------------------------------------------------------- wallpaper --
    print()
    print("Wallpaper")
    print("  Paste the full path to an image (Enter keeps the current one)")
    if args.wallpaper:
        src = clean_path(args.wallpaper)
        if not src.exists():
            sys.exit("No such file: %s" % src)
    else:
        src = ask("  > ")

    if src is None:
        print("  kept the current wallpaper")
        current = theme / WALL_NAME
        if current.exists():
            # still refresh the tint, so a theme.conf without it gets one
            tint, accent = extract_colors(current)
            update_conf(theme, {"TintColor": tint, "AccentColor": accent})
            print("  ✓ pill tint %s, accent %s (from the current wallpaper)"
                  % (tint, accent))
    else:
        tmpdir = tempfile.mkdtemp()
        try:
            wall = os.path.join(tmpdir, "background.jpg")
            blur = os.path.join(tmpdir, "background_blur.jpg")
            build_wallpaper(src, wall)
            build_blur(wall, blur)
            place(wall, theme / WALL_NAME)
            place(blur, theme / BLUR_NAME)
            tint, accent = extract_colors(wall)
            update_conf(theme, {"background": WALL_NAME, "backgroundBlur": BLUR_NAME,
                                "TintColor": tint, "AccentColor": accent})
            print("  ✓ %s" % WALL_NAME)
            print("  ✓ %s (blurred copy)" % BLUR_NAME)
            print("  ✓ pill tint %s, accent %s (taken from the wallpaper)" % (tint, accent))
        finally:
            shutil.rmtree(tmpdir, ignore_errors=True)

    # ------------------------------------------------------------- avatar --
    print()
    print("Profile picture")
    print("  Paste the full path to an image (Enter keeps the current one)")
    if args.avatar:
        src = clean_path(args.avatar)
        if not src.exists():
            sys.exit("No such file: %s" % src)
    else:
        src = ask("  > ")

    if src is None:
        print("  kept the current picture")
    else:
        tmpdir = tempfile.mkdtemp()
        try:
            avatar = os.path.join(tmpdir, "avatar.png")
            build_avatar(src, avatar)
            place(avatar, theme / AVATAR_NAME)
            update_conf(theme, {"AvatarImage": AVATAR_NAME})
            print("  ✓ %s" % AVATAR_NAME)
        finally:
            shutil.rmtree(tmpdir, ignore_errors=True)

    if not args.no_tip:
        print()
        print("Done. Restart the greeter to see it:")
        print("  sudo systemctl restart sddm")
        print()
        print("Change either one again at any time with:")
        print("  python3 %s" % os.path.join(theme, "configure.py"))
        print()


if __name__ == "__main__":
    main()
