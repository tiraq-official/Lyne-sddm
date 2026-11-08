#!/usr/bin/env python3
"""
configure.py — wallpaper and profile picture for the AnimeUnlock greeter.

Prompts for a path, copies the image into the theme's assets/ folder in the
format the theme expects, regenerates the blurred wallpaper from it, and points
theme.conf at the result. Run it again at any time to change either one.

    python3 configure.py                  # asks for both
    python3 configure.py --wallpaper ~/wall.png
    python3 configure.py --theme /usr/share/sddm/themes/AnimeUnlock

Press Enter at a prompt to keep what is already there.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageFilter
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
    im = Image.open(src)
    if im.mode not in ("RGB", "RGBA"):
        im = im.convert("RGBA")
    if max(im.size) > AVATAR_MAX:
        im.thumbnail((AVATAR_MAX, AVATAR_MAX), Image.LANCZOS)
    im.save(out, "PNG", optimize=True)


# ------------------------------------------------------------------ main ---

def main():
    ap = argparse.ArgumentParser(
        description="Set the wallpaper and profile picture for the AnimeUnlock theme.")
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
    print("AnimeUnlock — wallpaper & profile picture")
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
    else:
        tmpdir = tempfile.mkdtemp()
        try:
            wall = os.path.join(tmpdir, "background.jpg")
            blur = os.path.join(tmpdir, "background_blur.jpg")
            build_wallpaper(src, wall)
            build_blur(wall, blur)
            place(wall, theme / WALL_NAME)
            place(blur, theme / BLUR_NAME)
            update_conf(theme, {"background": WALL_NAME, "backgroundBlur": BLUR_NAME})
            print("  ✓ %s" % WALL_NAME)
            print("  ✓ %s (blurred copy)" % BLUR_NAME)
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
