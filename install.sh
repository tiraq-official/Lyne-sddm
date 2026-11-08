#!/usr/bin/env bash
#
# Install the Lyne-sddm SDDM theme, then ask for a wallpaper and a profile
# picture. Re-run with --reconfigure to change those later.
#
#   bash install.sh                # install + configure
#   bash install.sh --reconfigure  # just change wallpaper / profile picture
#
set -euo pipefail

THEME="Lyne-sddm"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/usr/share/sddm/themes/${THEME}"
DROPIN="/etc/sddm.conf.d/zz-lyne-sddm.conf"

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

# On a re-install, keep the wallpaper, profile picture and theme.conf you have
# already set up; everything else is refreshed from the repo.
EXCLUDES=(--exclude=./.git)
if [ -f "${DEST}/theme.conf" ]; then
    EXCLUDES+=(--exclude=./theme.conf)
    echo "    (existing theme.conf, wallpaper and picture kept)"
fi
for f in assets/background.jpg assets/background_blur.jpg assets/avatar.png; do
    if [ -f "${DEST}/${f}" ]; then
        EXCLUDES+=(--exclude=./${f})
    fi
done
tar -C "${SRC}" "${EXCLUDES[@]}" -cf - . | sudo tar -C "${DEST}" -xf -

echo
echo "==> Pointing SDDM at the theme"
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=%s\n' "${THEME}" | sudo tee "${DROPIN}" >/dev/null

# SDDM reads /etc/sddm.conf AFTER the sddm.conf.d drop-ins, so a Current=
# sitting in there wins over the drop-in we just wrote. Update it as well.
CONF="/etc/sddm.conf"
if [ -f "${CONF}" ] && grep -qE '^[[:space:]]*Current[[:space:]]*=' "${CONF}"; then
    echo "    ${CONF} also sets Current= (it overrides sddm.conf.d) - updating it"
    sudo cp "${CONF}" "${CONF}.bak"
    sudo sed -i "s|^[[:space:]]*Current[[:space:]]*=.*$|Current=${THEME}|" "${CONF}"
fi

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

# One-time note for anyone upgrading from the theme's old name.
if [ -f /etc/sddm.conf.d/zz-animeunlock.conf ] || [ -d /usr/share/sddm/themes/AnimeUnlock ]; then
    cat <<EOF

An older "AnimeUnlock" install is still on disk. Once this one looks right,
clear it out with:
  sudo rm -rf /usr/share/sddm/themes/AnimeUnlock
  sudo rm -f  /etc/sddm.conf.d/zz-animeunlock.conf
EOF
fi
