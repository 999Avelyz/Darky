#!/usr/bin/env bash
# Darky - uninstall. Removes the Darky colour scheme, Plasma style and GTK theme,
# and restores GTK settings. It does NOT remove the upstream Darkly engine
# (App Style / Decoration) - remove that from System Settings if you want.

set -u
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
have(){ command -v "$1" &>/dev/null; }

echo "Removing Darky colour scheme, Plasma style and GTK theme..."
rm -f  "$DATA/color-schemes/Darky.colors"
rm -rf "$DATA/plasma/desktoptheme/Darky"
rm -rf "$DATA/themes/Darky"
rm -f  "$CONF/gtk-4.0/gtk-darky.css"

# restore libadwaita gtk.css from the most recent backup, if any
last_bak="$(ls -1t "$CONF/gtk-4.0/gtk.css.bak.darky."* 2>/dev/null | head -1)"
if [[ -n "${last_bak:-}" ]]; then
  mv "$last_bak" "$CONF/gtk-4.0/gtk.css"
  echo "restored $CONF/gtk-4.0/gtk.css"
elif grep -q "Darky libadwaita" "$CONF/gtk-4.0/gtk.css" 2>/dev/null; then
  rm -f "$CONF/gtk-4.0/gtk.css"
fi

# reset GTK theme to Breeze
if have gsettings; then
  gsettings set org.gnome.desktop.interface gtk-theme 'Breeze' 2>/dev/null || true
fi

# revert Flatpak env overrides (best-effort)
if have flatpak; then
  sudo flatpak override --unset-env=QT_STYLE_OVERRIDE 2>/dev/null || true
fi

echo "Done. Pick another colour scheme / Plasma style in System Settings."
echo "To remove the Darkly engine too, uninstall it from Application Style & Window Decorations."
