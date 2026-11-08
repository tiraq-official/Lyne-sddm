# Lyne-sddm

**A [Lyne-dots](https://github.com/caioax/lyne-dots.git) lockscreen inspired sddm theme** A profile selector on the left, a desktop-session picker on the right, and a password bar that rises out of a blurred wallpaper the moment you start typing.


<p align="center">
  <img src="docs/banner.png">
</p>

## Features

**Your wallpaper, your colours**
Select your desired wallpaper it will dynamically adjust color.

**It blurs as you type**
Start typing, or click the pill, and the wallpaper cross-fades to its blurred copy while the password bar rises in. `Esc` on an empty field takes you back.

**Glass, not a flat box**
Every pill samples the wallpaper behind it, blurs it, and clips the result to its rounded shape.

**All of it is a config key**
Colours, spacing, fonts, the two chips, blur strength, power buttons — everything lives in `theme.conf` change if you want to have control.

## Install

```bash
git clone https://github.com/tiraq-official/Lyne-sddm.git
cd Lyne-sddm && bash install.sh
```

**Need to reconfigure again?** Re-run it any time:

```bash
bash /usr/share/sddm/themes/Lyne-sddm/install.sh --reconfigure
```

Preview it without logging out:

```bash
sddm-greeter --test-mode --theme /usr/share/sddm/themes/Lyne-sddm
```

Needs `python3` and Pillow — `sudo pacman -S python-pillow`, or `sudo apt install python3-pil`.

## Credits

- [Lyne-dots](https://github.com/caioax/lyne-dots.git): inspiration for lockscreen.