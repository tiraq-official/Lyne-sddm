#!/usr/bin/env bash
#
# Lyne-sddm — installer
#
#   bash install.sh                # install, then ask for wallpaper + picture
#   bash install.sh --reconfigure  # just change those two
#
set -euo pipefail

THEME="Lyne-sddm"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="/usr/share/sddm/themes/${THEME}"
DROPIN="/etc/sddm.conf.d/zz-lyne-sddm.conf"
CONF="/etc/sddm.conf"

# ------------------------------------------------------------------ colour --
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-dumb}" != "dumb" ]; then
    B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'
    if command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 256 ]; then
        A=$'\033[38;5;110m'; G=$'\033[38;5;114m'; X=$'\033[38;5;174m'
    else
        A=$'\033[36m'; G=$'\033[32m'; X=$'\033[31m'
    fi
    ANIM=1
else
    B=; D=; R=; A=; G=; X=; ANIM=0
fi

pause() { if [ "${ANIM}" -eq 1 ]; then sleep "${1:-0.02}" 2>/dev/null || true; fi; }

# a horizontal rule that draws itself in
rule() {
    local n="${1:-46}" i
    if [ "${ANIM}" -eq 1 ]; then
        printf '  %s' "${D}"
        for ((i = 0; i < n; i++)); do printf '─'; sleep 0.004 2>/dev/null || true; done
        printf '%s\n' "${R}"
    else
        printf '  %s\n' "$(printf '─%.0s' $(seq 1 "${n}"))"
    fi
}

# ------------------------------------------------------------------ banner --
banner() {
    local art=(
        "██╗     ██╗   ██╗███╗   ██╗███████╗"
        "██║     ╚██╗ ██╔╝████╗  ██║██╔════╝"
        "██║      ╚████╔╝ ██╔██╗ ██║█████╗  "
        "██║       ╚██╔╝  ██║╚██╗██║██╔══╝  "
        "███████╗   ██║   ██║ ╚████║███████╗"
        "╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝"
    )
    local line
    echo
    for line in "${art[@]}"; do
        printf '  %s%s%s%s\n' "${B}" "${A}" "${line}" "${R}"
        pause 0.018
    done
    pause 0.05
    printf '\n  %s           ·  s d d m  ·%s\n' "${D}" "${R}"
    pause 0.04
    printf '  %sA frosted-glass greeter that takes its colours from your wallpaper.%s\n\n' "${D}" "${R}"
    pause 0.05
}

# ------------------------------------------------------------------- steps --
run_step() {
    local label="$1"; shift
    if [ "${ANIM}" -eq 1 ]; then
        printf '  %s▸%s %s ' "${A}" "${R}" "${label}"
    fi
    if "$@" >/dev/null; then
        if [ "${ANIM}" -eq 1 ]; then
            printf '\r  %s✓%s %-56s\n' "${G}" "${R}" "${label}"
        else
            printf '  [ok] %s\n' "${label}"
        fi
        pause 0.06
    else
        if [ "${ANIM}" -eq 1 ]; then printf '\r'; fi
        printf '  %s✗%s %s\n' "${X}" "${R}" "${label}" >&2
        exit 1
    fi
}

# ------------------------------------------------------------------- work ---
install_files() {
    sudo mkdir -p "${DEST}"
    local excludes=(--exclude=./.git)
    # a re-install keeps the wallpaper, picture and settings you already set up
    if [ -f "${DEST}/theme.conf" ]; then
        excludes+=(--exclude=./theme.conf)
    fi
    local f
    for f in assets/background.jpg assets/background_blur.jpg assets/avatar.png; do
        if [ -f "${DEST}/${f}" ]; then
            excludes+=(--exclude=./${f})
        fi
    done
    tar -C "${SRC}" "${excludes[@]}" -cf - . | sudo tar -C "${DEST}" -xf -
}

point_sddm() {
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Theme]\nCurrent=%s\n' "${THEME}" | sudo tee "${DROPIN}" >/dev/null
    # SDDM reads /etc/sddm.conf AFTER the sddm.conf.d drop-ins, so a Current=
    # sitting in there beats the drop-in we just wrote.
    if [ -f "${CONF}" ] && grep -qE '^[[:space:]]*Current[[:space:]]*=' "${CONF}"; then
        sudo cp "${CONF}" "${CONF}.bak"
        sudo sed -i "s|^[[:space:]]*Current[[:space:]]*=.*$|Current=${THEME}|" "${CONF}"
    fi
}

usage() {
    cat <<EOF
Lyne-sddm — a frosted-glass greeter for SDDM

  bash install.sh                install, then ask for a wallpaper and picture
  bash install.sh --reconfigure  change those two without reinstalling
EOF
}

# ------------------------------------------------------------------- main ---
main() {
    case "${1:-}" in
        -h|--help) usage; exit 0 ;;
        --reconfigure)
            if [ ! -f "${DEST}/configure.py" ]; then
                printf '%sLyne-sddm is not installed at %s%s\n' "${X}" "${DEST}" "${R}" >&2
                printf 'Run this without --reconfigure first.\n' >&2
                exit 1
            fi
            exec python3 "${DEST}/configure.py" --theme "${DEST}"
            ;;
    esac

    banner

    printf '  %sYou may be asked for your password.%s\n\n' "${D}" "${R}"
    sudo -v

    run_step "Installing theme files" install_files
    run_step "Pointing SDDM at the theme" point_sddm

    echo
    rule 46
    printf '  %sWallpaper and profile picture%s\n' "${B}" "${R}"
    printf '  %sPress Enter to keep whatever is already set.%s\n\n' "${D}" "${R}"

    if python3 -c "import PIL" 2>/dev/null; then
        python3 "${DEST}/configure.py" --theme "${DEST}" --no-tip || true
    else
        printf '  %s!%s Pillow is missing, so the images could not be set up.\n' "${X}" "${R}"
        printf '    sudo pacman -S python-pillow      # or: sudo apt install python3-pil\n'
        printf '    then: bash %s/install.sh --reconfigure\n' "${DEST}"
    fi

    echo
    rule 46
    printf '  %s%-8s%s  %s\n' "${D}" "theme"   "${R}" "${DEST}"
    printf '  %s%-8s%s  %s\n' "${D}" "sddm"    "${R}" "${DROPIN}"
    printf '  %s%-8s%s  %s\n' "${D}" "preview" "${R}" "sddm-greeter --test-mode --theme ${DEST}"
    printf '  %s%-8s%s  %s\n' "${D}" "change"  "${R}" "bash ${DEST}/install.sh --reconfigure"
    rule 46
    echo
    printf '  %sLog out to see it, or:  sudo systemctl restart sddm%s\n\n' "${B}" "${R}"

    # one-time note for anyone upgrading from the theme's old name
    if [ -f /etc/sddm.conf.d/zz-animeunlock.conf ] || [ -d /usr/share/sddm/themes/AnimeUnlock ]; then
        printf '  %sAn older "AnimeUnlock" install is still on disk. Clear it with:%s\n' "${D}" "${R}"
        printf '    sudo rm -rf /usr/share/sddm/themes/AnimeUnlock\n'
        printf '    sudo rm -f  /etc/sddm.conf.d/zz-animeunlock.conf\n\n'
    fi
}

main "$@"
