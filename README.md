# Darky — Darkly, but OLED (pure black)

One coherent **true-black** theme for both KDE/Qt and GTK, built from
[Darkly](https://github.com/Bali10050/Darkly) with your OLED colour scheme.

## What you get

| System Settings section | Entry to pick | What it is |
|---|---|---|
| **Colors** | `Darky` | your OLED colour scheme (pure `#000000`, Complementary is black) |
| **Application Style** | `Darkly` | the Qt widget engine — renders your Darky colours |
| **Window Decorations** | `Darkly` | the titlebar engine |
| **Plasma Style** | `Darky` | OLED panels / plasmoids |
| GNOME/GTK App Style | `Darky` | GTK 2 / 3 / 4 + libadwaita apps |

### Why Application Style & Window Decorations say “Darkly”, not “Darky”

Those two are **compiled C++ plugins** that draw *shapes*, not colours — they
render whatever colour scheme is active. The entire OLED identity lives in the
**colour scheme**. So `Darky colours + Darkly engine` produces a result that is
pixel-for-pixel identical to a renamed “Darky” engine would, **without**
recompiling a fragile renamed fork of ~9,000 lines of C++. You install Darkly
once; the “Darky” name lives where it actually matters (Colors, Plasma, GTK).

If you truly want separate `Darky` entries under Application Style / Window
Decorations, that’s a full source fork + rebuild — ask and it can be done as a
separate project.

## Install

```bash
chmod +x install.sh
./install.sh
```

The script will:

1. `apt install` the Qt6/KF6 build dependencies.
2. Clone, build and install **upstream Darkly** (Qt6) → provides the Application
   Style + Window Decoration.
3. Install the **Darky** colour scheme, Plasma style and GTK 2/3/4 theme.
4. Apply everything (colour scheme, styles, `gsettings` GTK theme, KWin reload).
5. Optionally set up **Flatpak** (runs last): filesystem overrides, downloads &
   installs the Darkly runtime, and applies the Flatseal-equivalent env
   overrides (`QT_STYLE_OVERRIDE=Darkly`, `QT_QPA_PLATFORMTHEME=kde`,
   `xdg-config/darklyrc:ro`).

Log out and back in afterwards so the Qt style and decoration settle.

### GTK — three ways to apply it
The theme installs to `~/.local/share/themes/Darky`, so you can select it from:
- `gsettings set org.gnome.desktop.interface gtk-theme 'Darky'` (done automatically),
- **KDE** → System Settings → Application Style → *Configure GNOME/GTK Application Style*,
- **nwg-look**.

## The protontricks / winetricks checkbox fix

On pure black, protontricks’ GTK dialog (YAD) showed a **red broken square**
instead of a checkmark. Cause: the bundled checkmark **asset failed to load** in
the sandbox, so GTK drew its red “missing image” placeholder. The Darky GTK
theme fixes this three ways:

1. **Visible box on black** — checkboxes/radios get a slightly-lifted `#161616`
   fill and a 1px border so they never vanish into `#000000`.
2. **Accent, never red/black** — the checked state is the blue accent `#1b91d5`
   with a light checkmark.
3. **Icon fallback** — the `-gtk-icon-source` list ends with system symbolic
   icons (`object-select-symbolic`, …), so if the bundled asset can’t load, GTK
   uses a real icon instead of the red placeholder. Assets are shipped as **real
   files** (not symlinks) for exactly this reason.

The fix is applied to regular checkboxes/radios **and** to `treeview`/list cells,
which is what YAD/protontricks checklists actually use.

## Qt5 apps (optional)

The build targets **Qt6** (matching the provided dependency list). For Qt5 apps
under Plasma 6, uncomment the Qt5 dependency block in `install.sh` (it also sets
`DARKLY_BUILD_ARG=""` so Darkly builds both Qt5 and Qt6).

## Uninstall

```bash
./uninstall.sh
```

Removes the Darky colour scheme, Plasma style and GTK theme and restores GTK
settings. The Darkly engine stays installed — remove it from Application Style /
Window Decorations if you want it gone too.

## Notes / credits

- Based on **Darkly** and **darkly-gtk** (GPLv2 / LGPL-2.1) by Bali10050 & contributors.
- The Darky GTK CSS is pre-compiled — no `sassc` needed at install time.
- Both `gtk.css` and `gtk-dark.css` are the OLED build, so apps requesting either
  variant stay black.
