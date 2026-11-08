#!/usr/bin/env bash
#
# Install the AnimeUnlock SDDM theme, then ask for a wallpaper and a profile
# picture. Re-run with --reconfigure to change those later.
#
#   bash install.sh                # install + configure
#   bash install.sh --reconfigure  # just change wallpaper / profile picture
#
set -euo pipefail

THEME="AnimeUnlock"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/usr/share/sddm/themes/${THEME}"
DROPIN="/etc/sddm.conf.d/zz-animeunlock.conf"

# ---------------------------------------------------------------- reconfigure
if [ "${1:-}" = "--reconfigure" ]; then
    if [ ! -f "${DEST}/configure.py" ]; then
        echo "The theme is not installed at ${DEST}." >&2
        echo "Run this without --reconfigure first." >&2
        exit 1
    fi
    exec python3 "${DEST}/configure.py" --theme "${DEST}"
fi

if [ "$(id -u)" -eq 0 ]; then
    echo "!! Running as root: ~ will point at /root, so pasted paths like"
    echo "   ~/Pictures/wall.png will not resolve. Prefer:  bash install.sh"
    echo
fi

# ------------------------------------------------------------------- install
echo "==> Installing ${THEME} to ${DEST}"
sudo mkdir -p "${DEST}"
tar -C "${SRC}" --exclude=./.git -cf - . | sudo tar -C "${DEST}" -xf -

echo
echo "==> Pointing SDDM at the theme"
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=%s\n' "${THEME}" | sudo tee "${DROPIN}" >/dev/null

# --------------------------------------------------------------- configure
if python3 -c "import PIL" 2>/dev/null; then
    python3 "${DEST}/configure.py" --theme "${DEST}" --no-tip || true
else
    echo
    echo "!! Pillow is missing, so the wallpaper and profile picture could not be"
    echo "   set up. Install it and re-run the configuration:"
    echo "     sudo pacman -S python-pillow        # Arch"
    echo "     sudo apt install python3-pil        # Debian/Ubuntu"
    echo "     bash ${DEST}/install.sh --reconfigure"
fi

cat <<EOF

Done.
  Theme folder : ${DEST}
  SDDM drop-in : ${DROPIN}

Preview it without logging out:
  sddm-greeter --test-mode --theme ${DEST}

Log out, or:  sudo systemctl restart sddm

Change the wallpaper or profile picture later:
  bash ${DEST}/install.sh --reconfigure
EOF
