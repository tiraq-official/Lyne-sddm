# AnimeUnlock

**A frosted-glass greeter for SDDM.** A profile selector on the left, a session selector on the right, and a password bar that rises out of a blurred wallpaper the moment you start typing.

[![SDDM](https://img.shields.io/badge/SDDM-greeter-0b1626?style=flat-square)](https://github.com/sddm/sddm) [![Qt](https://img.shields.io/badge/Qt-QML-41CD52?style=flat-square&logo=qt&logoColor=white)](https://qt.io) [![License](https://img.shields.io/badge/license-GPL--3.0--or--later-8ec5ff?style=flat-square)](https://www.gnu.org/licenses/gpl-3.0.html) [![Last commit](https://img.shields.io/github/last-commit/tiraq-official/AnimeUnlock?style=flat-square&color=9ece6a)](https://github.com/tiraq-official/AnimeUnlock/commits)

[Screens](#screens) · [Highlights](#highlights) · [Install](#install) · [Configure](#configure) · [Credits](#credits)

## Screens

| Idle | Unlocking |
| :-: | :-: |
| ![Idle](Previews/idle.png) | ![Unlocking](Previews/entry.png) |

## Highlights

**Two selectors, where you wanted them**
The account picker sits to the left of the unlock pill, the desktop-session picker to its right — in both the idle and the unlocking state.

**It blurs as you type**
Start typing, or click the pill, and the wallpaper cross-fades to a blurred copy while the password bar rises in its place. `Esc` on an empty field takes you back.

**Glass, not a flat box**
Every pill samples the wallpaper behind it, blurs it and clips it to its rounded shape. Turn it off with `PillFrost` if you'd rather have plain fills.

## Install

```bash
git clone https://github.com/tiraq-official/AnimeUnlock.git
cd AnimeUnlock && bash install.sh
```

It copies the theme to `/usr/share/sddm/themes/AnimeUnlock`, points SDDM at it, then asks for two paths:

1. **Wallpaper** — copied into `assets/`, and the blurred copy the unlock transition fades to is regenerated from it.
2. **Profile picture** — copied in and shown as the circle in the password bar.

Paste the full path to each; press Enter to keep what is already there. Change either one later with:

```bash
bash /usr/share/sddm/themes/AnimeUnlock/install.sh --reconfigure
```

Preview it without logging out:

```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/AnimeUnlock
```

## Configure

Everything lives in `theme.conf`.

| Key | |
| --- | --- |
| `background`, `backgroundBlur` | the two wallpapers; after swapping one, run `python3 make_blur.py` |
| `AvatarImage` | the round avatar — empty uses the account's own picture, or give a path |
| `PromptText` · `WeatherText` · `ShowWeather` | the two chips |
| `PillFrost`, `PillBlurRadius` | the frosted glass |
| `TintColor`, `AccentColor` | written by `configure.py` from the wallpaper — the pills, borders and hover states follow it |
| `AlwaysShowPowerButtons` | keep suspend / restart / power visible in `--test-mode` |
| `DimBackground`, `BlurDuration` | dimming and cross-fade |

## Credits

Accounts and sessions come straight from SDDM, so the selectors always match the machine. The icons are drawn on a Canvas, and the blur ships for both Qt 5 and Qt 6 and picks whichever the greeter can load — no icon fonts, no extra assets.

GPL-3.0-or-later.
