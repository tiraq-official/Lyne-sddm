# Lyne-sddm

**A frosted-glass greeter for SDDM that takes its colours from your wallpaper.** A profile selector on the left, a desktop-session picker on the right, and a password bar that rises out of a blurred wallpaper the moment you start typing.

[![SDDM](https://img.shields.io/badge/SDDM-greeter-0b1626?style=flat-square)](https://github.com/sddm/sddm) [![Qt](https://img.shields.io/badge/Qt-QML-41CD52?style=flat-square&logo=qt&logoColor=white)](https://qt.io) [![License](https://img.shields.io/badge/license-GPL--3.0--or--later-8ec5ff?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.html) [![Last commit](https://img.shields.io/github/last-commit/tiraq-official/Lyne-sddm?style=flat-square&color=9ece6a)](https://github.com/tiraq-official/Lyne-sddm/commits)

[Screens](#screens) · [Features](#features) · [Install](#install) · [Configure](#configure) · [How it works](#how-it-works)

## Screens

| Idle | Unlocking |
| :-: | :-: |
| ![Idle](Previews/idle.png) | ![Unlocking](Previews/entry.png) |

## Features

**Your wallpaper, your colours**
Point it at an image and it copies it in, generates the blurred twin the unlock screen fades to, and tints every pill and accent from that wallpaper's dominant colour — a green wallpaper gives green glass, an orange one gives orange.

**Two selectors, where you wanted them**
The account picker sits to the left of the unlock pill, the session picker to its right, in both the idle and the unlocking state. Both lists come straight from SDDM, so they always match the machine.

**It blurs as you type**
Start typing, or click the pill, and the wallpaper cross-fades to its blurred copy while the password bar rises in. `Esc` on an empty field takes you back.

**Glass, not a flat box**
Every pill samples the wallpaper behind it, blurs it, and clips the result to its rounded shape.

**All of it is a config key**
Colours, spacing, fonts, the two chips, blur strength, power buttons — everything lives in `theme.conf`.

## Install

```bash
git clone https://github.com/tiraq-official/Lyne-sddm.git
cd Lyne-sddm && bash install.sh
```

It copies the theme to `/usr/share/sddm/themes/Lyne-sddm`, points SDDM at it, then asks for two paths:

1. **Wallpaper** — copied into `assets/`; the blurred copy and the pill tint are derived from it.
2. **Profile picture** — centre-cropped into a circle for the password bar.

Paste the full path to each. **Enter keeps whatever is already set**, so you can change just one. Re-run it any time:

```bash
bash /usr/share/sddm/themes/Lyne-sddm/install.sh --reconfigure
```

Preview it without logging out:

```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/Lyne-sddm
```

Needs `python3` and Pillow — `sudo pacman -S python-pillow`, or `sudo apt install python3-pil`.

## Configure

Everything lives in `theme.conf`.

| Key | |
| --- | --- |
| `background`, `backgroundBlur` | the two wallpapers; after swapping one by hand, run `python3 make_blur.py` |
| `TintColor`, `AccentColor` | written by `configure.py` from the wallpaper — pills, borders and hover states follow them |
| `AvatarImage` | the round avatar — empty uses the account's own picture, or give a path |
| `PromptText` · `WeatherText` · `ShowWeather` | the two chips |
| `PillFrost`, `PillBlurRadius` | the frosted glass |
| `AlwaysShowPowerButtons` | keep suspend / restart / power visible under `--test-mode` |
| `DimBackground`, `BlurDuration` | dimming and cross-fade |
| `FontFamily`, `MonoFontFamily` | UI and monospace fonts |

## How it works

Accounts and sessions come from SDDM. Icons are drawn on a Canvas, so there are no icon fonts and no image assets. The blur ships for both Qt 5 (`QtGraphicalEffects`) and Qt 6 (`Qt5Compat.GraphicalEffects`), and the theme probes which one your greeter can load — if neither is available the pills simply stay solid.

```
Lyne-sddm/
├── Main.qml            greeter entry point: background, flow, palette
├── theme.conf          every knob
├── configure.py        wallpaper + profile picture + tint
├── install.sh          install, or --reconfigure
├── make_blur.py        rebuild the blurred wallpaper by hand
├── metadata.desktop    theme metadata
├── components/         one file per widget
├── assets/             wallpapers and avatar
└── Previews/           the screenshots above
```

GPL-3.0-or-later.
