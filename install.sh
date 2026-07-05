#!/usr/bin/env bash
# =====================================================================
#  Darky - True OLED Fork Installer
#  Compiles the local 'src/' folder and installs the Darky OLED theme.
#  NO "Darkly" names left in configs, rc files, or environment variables.
#  Result: Pure "Darky" everywhere. QT5 completely removed.
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

c()  { printf '\033[1;36m==>\033[0m %s\n' "$1"; }
ok() { printf '\033[1;32m  ok\033[0m %s\n' "$1"; }
warn(){ printf '\033[1;33m  !!\033[0m %s\n' "$1"; }
have(){ command -v "$1" &>/dev/null; }

echo
echo "  Darky (True OLED Fork) installer"
echo "  ---------------------------------"
echo "  This will: install build deps, compile the local Darky engine (Qt6 ONLY),"
echo "  install the Darky colour scheme + Plasma style + GTK2/3/4 theme,"
echo "  apply them, and (optionally) set up Flatpak."
echo
read -rp "  Continue? [y/N] " ans
[[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]] || { echo "Aborted."; exit 0; }

# =====================================================================
# 1. Clean up old Darkly / conflicting themes
# =====================================================================
c "Removing old Darkly/Default conflicts"
rm -f "$COLOR_DIR/Darkly.colors"
rm -rf "$PLASMA_DIR/Darkly"
rm -rf "$THEMES_DIR/Darkly"
rm -f "$CONF/darklyrc"        # Remove old darklyrc if it exists
ok "Cleaned up old theme files"

# =====================================================================
# 2. Build dependencies (Qt6 / KF6)
# =====================================================================
c "Installing build dependencies"
if have apt; then
  sudo apt install -y \
      extra-cmake-modules cmake build-essential \
      qt6-base-dev qt6-base-dev-tools \
      libkf6coreaddons-dev libkf6config-dev libkf6guiaddons-dev \
      libkf6i18n-dev libkf6iconthemes-dev libkf6windowsystem-dev \
      libkf6colorscheme-dev libkirigami-dev \
  && ok "dependencies installed" || warn "apt reported an error - check the packages above"
elif have dnf; then
  sudo dnf install -y \
      git cmake extra-cmake-modules gcc gcc-c++ make \
      qt6-qtbase-devel qt6-qttools-devel qt6-qtdeclarative-devel \
      qt6-qtsvg-devel qt6-qtwayland-devel \
      "cmake(KDecoration3)" kwin-devel \
      kf6-kcoreaddons-devel kf6-kconfig-devel kf6-kconfigwidgets-devel \
      kf6-kguiaddons-devel kf6-ki18n-devel kf6-kiconthemes-devel \
      kf6-kwindowsystem-devel kf6-kcolorscheme-devel kf6-kcmutils-devel \
      kf6-kirigami-devel kf6-frameworkintegration-devel \
      kf6-kpackage-devel kf6-kservice-devel kf6-kwidgetsaddons-devel \
      kf6-kcodecs-devel kf6-karchive-devel kf6-knotifications-devel \
  && ok "dependencies installed" || warn "dnf reported an error - check the packages above"
else
  warn "No supported package manager (apt/dnf) found - install the Qt6/KF6 dev packages manually for your distro, then re-run."
fi

# =====================================================================
# 3. Build & install Darky Engine (from local src/ - QT6 ONLY)
# =====================================================================
c "Building & installing Darky engine (Qt6 only)"
if have cmake; then
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"
  cd "$BUILD_DIR"

  # Pass the correct flag to CMakeLists.txt
  cmake "$SRC/src" -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_QT6=ON \
    && ok "CMake configured (Qt6 only)" \
    || { warn "CMake configuration failed"; exit 1; }

  make -j$(nproc) \
    && ok "Darky compiled" \
    || { warn "Compilation failed"; exit 1; }

  sudo make install \
    && ok "Darky engine installed system-wide" \
    || warn "Installation failed"
else
  warn "cmake missing - skipping Darky engine build"
fi

# =====================================================================
# 4. Install the Darky COLOUR SCHEME  (System Settings > Colors)
# =====================================================================
c "Installing Darky OLED colour scheme"
mkdir -p "$COLOR_DIR"
cp "$SRC/color-schemes/Darky.colors" "$COLOR_DIR/Darky.colors"
ok "$COLOR_DIR/Darky.colors"

# =====================================================================
# 5. Install the Darky PLASMA STYLE  (System Settings > Plasma Style)
# =====================================================================
c "Installing Darky Plasma style"
mkdir -p "$PLASMA_DIR"
rm -rf "$PLASMA_DIR/Darky"
cp -r "$SRC/plasma-desktoptheme/Darky" "$PLASMA_DIR/Darky"
ok "$PLASMA_DIR/Darky"

# =====================================================================
# 6. Install the Darky GTK theme  (GTK2/3/4 + libadwaita)
# =====================================================================
c "Installing Darky GTK theme (2/3/4)"
mkdir -p "$THEMES_DIR"
rm -rf "$THEMES_DIR/Darky"
cp -r "$SRC/gtk/Darky" "$THEMES_DIR/Darky"
ok "$THEMES_DIR/Darky"

c "Enabling libadwaita (GTK4) support"
mkdir -p "$GTK4_CONF"
if [[ -f "$GTK4_CONF/gtk.css" ]] && ! grep -q "Darky libadwaita" "$GTK4_CONF/gtk.css" 2>/dev/null; then
  cp "$GTK4_CONF/gtk.css" "$GTK4_CONF/gtk.css.bak.darky.$(date +%s)"
  warn "backed up existing $GTK4_CONF/gtk.css"
fi

# Rename asset references from darkly to darky in the CSS and folder
mkdir -p "$GTK4_CONF/darky-gtk-assets"
if [[ -f "$SRC/gtk/Darky/gtk-4.0/gtk.css" ]]; then
  sed 's/darkly-gtk-assets/darky-gtk-assets/g' "$SRC/gtk/Darky/gtk-4.0/gtk.css" > "$GTK4_CONF/gtk-darky.css"
fi
cp "$SRC/gtk/Darky/gtk-4.0/darkly-gtk-assets/"* "$GTK4_CONF/darky-gtk-assets/" 2>/dev/null || true

printf '/* Darky libadwaita - do not edit, regenerated by installer */\n@import "gtk-darky.css";\n' > "$GTK4_CONF/gtk.css"
ok "libadwaita theme active"

# Create the native darkyrc config file
[[ -f "$CONF/darkyrc" ]] || printf '[Common]\nCornerRadius=9\n' > "$CONF/darkyrc"

# =====================================================================
# 7. Apply everything as DARKY
# =====================================================================
c "Applying the theme"
KW=kwriteconfig6; have kwriteconfig6 || KW=kwriteconfig5

# App Style = Darky
 $KW --file kdeglobals --group KDE --key widgetStyle Darky 2>/dev/null && ok "application style -> Darky"

# Window decoration = Darky
 $KW --file kwinrc --group org.kde.kdecoration2 --key library org.kde.darky 2>/dev/null
 $KW --file kwinrc --group org.kde.kdecoration2 --key theme Darky 2>/dev/null && ok "window decoration -> Darky"

# Colour scheme = Darky
if have plasma-apply-colorscheme; then plasma-apply-colorscheme Darky &>/dev/null && ok "colour scheme -> Darky"
else $KW --file kdeglobals --group General --key ColorScheme Darky 2>/dev/null; fi

# Plasma style = Darky
have plasma-apply-desktoptheme && plasma-apply-desktoptheme Darky &>/dev/null && ok "plasma style -> Darky"

# GTK theme = Darky
if have gsettings; then
  gsettings set org.gnome.desktop.interface gtk-theme    'Darky'        2>/dev/null
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'  2>/dev/null
  ok "gsettings gtk-theme -> Darky"
else
  warn "gsettings not found - set the GTK theme to 'Darky' via nwg-look or KDE GTK config"
fi
 $KW --file kdeglobals --group KDE-GTK-Config --key gtkTheme Darky 2>/dev/null || true

# Reload KWin so the decoration/style take effect
for q in qdbus6 qdbus qdbus-qt6; do
  have "$q" && "$q" org.kde.KWin /KWin reconfigure &>/dev/null && break
done

# =====================================================================
# 8. Flatpak  (run last, after everything is installed)
# =====================================================================
echo
read -rp "  Set up Flatpak (Runtime + Flatseal overrides)? [y/N] " fp
if [[ "${fp,,}" == "y" || "${fp,,}" == "yes" ]] && have flatpak; then
  c "Configuring Flatpak"
  # filesystem access to the user themes + gtk4 config
  sudo flatpak override --filesystem=xdg-data/themes
  sudo flatpak override --filesystem=xdg-config/gtk-4.0
  sudo flatpak override --filesystem=xdg-data/color-schemes:ro

  # Install the Darkly KDE-runtime extension from a LOCAL bundle (no download).
  # We still need this to provide Qt6 libraries inside the sandbox.
  # The bundle must sit next to install.sh and be named Darkly-QT*.flatpak
  # (the user picks whichever Qt runtime version they downloaded).
  shopt -s nullglob
  FLATPAK_MATCHES=( "$SRC"/Darkly-QT*.flatpak )
  shopt -u nullglob

  if (( ${#FLATPAK_MATCHES[@]} == 0 )); then
    warn "no file found - there is no Darkly-QT*.flatpak next to install.sh"
    echo "     How to get it:"
    echo "       1. Open  https://github.com/Bali10050/Darkly/releases/latest"
    echo "       2. Go to the latest tag and open the 'Assets' section."
    echo "       3. Check your Qt version in:"
    echo "          System Settings > About this System  (the 'Qt Version' line)."
    echo "       4. Download the .flatpak that matches your Qt version"
    echo "          (e.g. Qt 6.9 -> ...qt6.9...,  Qt 6.10 -> ...qt6.10...)."
    echo "       5. Copy it here and rename it to  Darkly-QT<version>.flatpak"
    echo "          (e.g. Darkly-QT6.10-0.5.38.flatpak), then run the installer again."
  else
    FLATPAK_FILE="${FLATPAK_MATCHES[0]}"
    c "Using $(basename "$FLATPAK_FILE")"
    sudo flatpak install --system -y "$FLATPAK_FILE" \
      && ok "Flatpak runtime installed" \
      || warn "Flatpak install failed - adjust the runtime version (qt6.x) to match yours"
  fi

  # --- Flatseal-equivalent overrides (Everything renamed to Darky) ---
  sudo flatpak override --env=QT_STYLE_OVERRIDE=Darky
  sudo flatpak override --env=QT_QPA_PLATFORMTHEME=kde
  sudo flatpak override --filesystem=xdg-config/darkyrc:ro

  ok "Flatpak env overrides set (QT_STYLE_OVERRIDE=Darky, darkyrc:ro)"
else
  [[ "${fp,,}" == "y" || "${fp,,}" == "yes" ]] && warn "flatpak not installed - skipping"
fi

echo
echo "  Done! Log out & back in (or restart apps) for everything to settle."
echo "  Check System Settings: Colors, App Style, Win Deco, Plasma Style should all say 'Darky'."
echo
