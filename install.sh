#!/usr/bin/env bash
# =====================================================================
#  Darky - install script
#  Darkly, but OLED (pure black). Installs one coherent theme across:
#    - Colors           -> "Darky" colour scheme
#    - Application Style -> "Darkly" (the Qt engine; renders your Darky colours)
#    - Window Decorations-> "Darkly"
#    - Plasma Style      -> "Darky"
#    - GTK 2 / 3 / 4     -> "Darky" (works via gsettings, nwg-look or KDE GTK config)
#
#  Why the App Style / Decoration entries read "Darkly":
#  those two are COMPILED, colour-agnostic engines. The OLED look is
#  carried by the *colour scheme*, so "Darky colours + Darkly engine"
#  gives a pixel-identical OLED result without recompiling a renamed fork.
# =====================================================================

set -u
SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# ---- paths ----------------------------------------------------------
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
COLOR_DIR="$DATA/color-schemes"
PLASMA_DIR="$DATA/plasma/desktoptheme"
THEMES_DIR="$DATA/themes"
GTK4_CONF="$CONF/gtk-4.0"
BUILD_DIR="${TMPDIR:-/tmp}/darky-build"
DARKLY_REF="v0.5.38"                       # upstream Darkly release to build
FLATPAK_FILE="darkly-qt6.9-0.5.38-x86_64.flatpak"
FLATPAK_URL="https://github.com/Bali10050/Darkly/releases/download/${DARKLY_REF}/${FLATPAK_FILE}"

c()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
ok() { printf '\033[1;32m  ok\033[0m %s\n' "$1"; }
warn(){ printf '\033[1;33m  !!\033[0m %s\n' "$1"; }
have(){ command -v "$1" &>/dev/null; }

echo
echo "  Darky (Darkly OLED) installer"
echo "  ---------------------------------"
echo "  This will: install build deps, build & install upstream Darkly (Qt6),"
echo "  install the Darky colour scheme + Plasma style + GTK2/3/4 theme,"
echo "  apply them, and (optionally) set up Flatpak."
echo
read -rp "  Continue? [y/N] " ans
[[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]] || { echo "Aborted."; exit 0; }

# =====================================================================
# 1. Build dependencies (Qt6 / KF6)
# =====================================================================
c "Installing build dependencies"
if have apt; then
  sudo apt install -y \
      extra-cmake-modules \
      cmake \
      build-essential \
      qt6-base-dev \
      qt6-base-dev-tools \
      libkf6coreaddons-dev \
      libkf6config-dev \
      libkf6guiaddons-dev \
      libkf6i18n-dev \
      libkf6iconthemes-dev \
      libkf6windowsystem-dev \
      libkf6colorscheme-dev \
      libkirigami-dev \
  && ok "dependencies installed" || warn "apt reported an error - check the packages above"

  # Optional Qt5 support (Qt5 apps under Plasma 6). Uncomment if you need it:
  # sudo apt install -y qtbase5-dev qtdeclarative5-dev libkf5config-dev \
  #     libkf5configwidgets-dev libkf5coreaddons-dev libkf5guiaddons-dev \
  #     libkf5iconthemes-dev libkf5windowsystem-dev libkf5kcmutils-dev \
  #     libkdecorations2-dev libqt5x11extras5-dev && DARKLY_BUILD_ARG=""
else
  warn "apt not found - install the Qt6/KF6 dev packages manually for your distro, then re-run."
fi

# =====================================================================
# 2. Build & install upstream Darkly  (Application Style + Window Decoration)
# =====================================================================
c "Building & installing Darkly (Qt6 engine)"
if have cmake && have git; then
  rm -rf "$BUILD_DIR"
  git clone --single-branch --depth=1 --branch "$DARKLY_REF" \
      https://github.com/Bali10050/Darkly.git "$BUILD_DIR" \
    || git clone --single-branch --depth=1 https://github.com/Bali10050/Darkly.git "$BUILD_DIR"
  if [[ -f "$BUILD_DIR/install.sh" ]]; then
    ( cd "$BUILD_DIR" && chmod +x install.sh && ./install.sh "${DARKLY_BUILD_ARG:-QT6}" ) \
      && ok "Darkly engine installed" \
      || warn "Darkly build failed - the App Style / Decoration entries may be missing"
  else
    warn "Darkly install.sh not found in clone"
  fi
else
  warn "cmake/git missing - skipping Darkly engine build"
fi

# =====================================================================
# 3. Install the Darky COLOUR SCHEME  (System Settings > Colors)
# =====================================================================
c "Installing Darky colour scheme"
mkdir -p "$COLOR_DIR"
cp "$SRC/color-schemes/Darky.colors" "$COLOR_DIR/Darky.colors"
ok "$COLOR_DIR/Darky.colors"

# =====================================================================
# 4. Install the Darky PLASMA STYLE  (System Settings > Plasma Style)
# =====================================================================
c "Installing Darky Plasma style"
mkdir -p "$PLASMA_DIR"
rm -rf "$PLASMA_DIR/Darky"
cp -r "$SRC/plasma-desktoptheme/Darky" "$PLASMA_DIR/Darky"
ok "$PLASMA_DIR/Darky"

# =====================================================================
# 5. Install the Darky GTK theme  (GTK2/3/4 + libadwaita)
# =====================================================================
c "Installing Darky GTK theme (2/3/4)"
mkdir -p "$THEMES_DIR"
rm -rf "$THEMES_DIR/Darky"
cp -r "$SRC/gtk/Darky" "$THEMES_DIR/Darky"
ok "$THEMES_DIR/Darky"

# libadwaita: many GTK4/libadwaita apps ignore themes unless dropped in ~/.config/gtk-4.0
c "Enabling libadwaita (GTK4) support"
mkdir -p "$GTK4_CONF"
if [[ -f "$GTK4_CONF/gtk.css" ]] && ! grep -q "Darky libadwaita" "$GTK4_CONF/gtk.css" 2>/dev/null; then
  cp "$GTK4_CONF/gtk.css" "$GTK4_CONF/gtk.css.bak.darky.$(date +%s)"
  warn "backed up existing $GTK4_CONF/gtk.css"
fi
mkdir -p "$GTK4_CONF/darkly-gtk-assets"
cp "$SRC/gtk/Darky/gtk-4.0/darkly-gtk-assets/"* "$GTK4_CONF/darkly-gtk-assets/" 2>/dev/null || true
cp "$SRC/gtk/Darky/gtk-4.0/gtk.css" "$GTK4_CONF/gtk-darky.css"
printf '/* Darky libadwaita - do not edit, regenerated by installer */\n@import "gtk-darky.css";\n' > "$GTK4_CONF/gtk.css"
ok "libadwaita theme active"

# minimal darklyrc so Flatpak :ro mount + style defaults are consistent
[[ -f "$CONF/darklyrc" ]] || printf '[Common]\nCornerRadius=9\n' > "$CONF/darklyrc"

# =====================================================================
# 6. Apply everything
# =====================================================================
c "Applying the theme"
KW=kwriteconfig6; have kwriteconfig6 || KW=kwriteconfig5
# App Style = Darkly (renders the Darky colours)
$KW --file kdeglobals --group KDE --key widgetStyle Darkly 2>/dev/null && ok "application style -> Darkly"
# Window decoration = Darkly
$KW --file kwinrc --group org.kde.kdecoration2 --key library org.kde.darkly 2>/dev/null
$KW --file kwinrc --group org.kde.kdecoration2 --key theme Darkly 2>/dev/null && ok "window decoration -> Darkly"
# Colour scheme = Darky
if have plasma-apply-colorscheme; then plasma-apply-colorscheme Darky &>/dev/null && ok "colour scheme -> Darky"
else $KW --file kdeglobals --group General --key ColorScheme Darky 2>/dev/null; fi
# Plasma style = Darky
have plasma-apply-desktoptheme && plasma-apply-desktoptheme Darky &>/dev/null && ok "plasma style -> Darky"

# GTK theme = Darky (read by GNOME apps, nwg-look and KDE's GTK config)
if have gsettings; then
  gsettings set org.gnome.desktop.interface gtk-theme    'Darky'        2>/dev/null
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'  2>/dev/null
  ok "gsettings gtk-theme -> Darky"
else
  warn "gsettings not found - set the GTK theme to 'Darky' via nwg-look or KDE GTK config"
fi
# also record it for kde-gtk-config
$KW --file kdeglobals --group KDE-GTK-Config --key gtkTheme Darky 2>/dev/null || true

# reload KWin so the decoration/style take effect
for q in qdbus6 qdbus qdbus-qt6; do
  have "$q" && "$q" org.kde.KWin /KWin reconfigure &>/dev/null && break
done

# =====================================================================
# 7. Flatpak  (run last, after everything is installed)
# =====================================================================
echo
read -rp "  Set up Flatpak (Darkly runtime + Flatseal overrides)? [y/N] " fp
if [[ "${fp,,}" == "y" || "${fp,,}" == "yes" ]] && have flatpak; then
  c "Configuring Flatpak"
  # filesystem access to the user themes + gtk4 config
  sudo flatpak override --filesystem=xdg-data/themes
  sudo flatpak override --filesystem=xdg-config/gtk-4.0
  sudo flatpak override --filesystem=xdg-data/color-schemes:ro

  # download & install the Darkly KDE-runtime extension (Qt6.9 build)
  ( cd "${TMPDIR:-/tmp}" \
    && { curl -L -o "$FLATPAK_FILE" "$FLATPAK_URL" || wget -O "$FLATPAK_FILE" "$FLATPAK_URL"; } \
    && sudo flatpak install --system -y "./$FLATPAK_FILE" ) \
    && ok "Darkly flatpak installed" \
    || warn "Darkly flatpak download/install failed - adjust the runtime version (qt6.x) to match yours"

  # --- the Flatseal-equivalent overrides (env vars + darklyrc access) ---
  sudo flatpak override --env=QT_STYLE_OVERRIDE=Darkly
  sudo flatpak override --env=QT_QPA_PLATFORMTHEME=kde
  sudo flatpak override --filesystem=xdg-config/darklyrc:ro
  ok "Flatpak env overrides set (QT_STYLE_OVERRIDE=Darkly, QT_QPA_PLATFORMTHEME=kde)"
else
  [[ "${fp,,}" == "y" || "${fp,,}" == "yes" ]] && warn "flatpak not installed - skipping"
fi

echo
echo "  Done. Log out & back in (or restart apps) for everything to settle."
echo "  If any entry isn't auto-selected, pick it in System Settings:"
echo "    Colors=Darky · Application Style=Darkly · Window Decorations=Darkly ·"
echo "    Plasma Style=Darky · GNOME/GTK App Style=Darky"
echo
