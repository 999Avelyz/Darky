#!/usr/bin/env bash
# =============================================================================
#  darklyoled-gtk.sh   (GTK2 + GTK3 + GTK4)
#
#  Legge la palette KDE  ~/.local/share/color-schemes/DarklyOLED.colors
#  e ne DERIVA i colori GTK di Darkly, generando un tema OLED autonomo:
#
#     ~/.local/share/themes/Darkly-OLED   (gtk-2.0, gtk-3.0, gtk-4.0)
#
#  Poi applica gli stessi colori a ~/.gtkrc-2.0, ~/.config/gtk-3.0 e gtk-4.0,
#  cosi' diventano OLED:
#    - le app GTK2               (via gtk-color-scheme in ~/.gtkrc-2.0 + tema)
#    - le app GTK3/GTK4 "pure"   (seguono il nome del tema)
#    - le app libadwaita         (ignorano il tema, leggono la config gtk-4.0)
#
#  Mappa palette -> GTK:
#    [Colors:Window]    Background -> sfondo finestre/header/titlebar
#    [Colors:View]      Background -> sfondo viste/liste/campi testo
#    [Colors:Button]    Background -> sfondo bottoni
#    [Colors:Selection] Background -> accento (evidenziazione)
#    Decoration/Link/Negative/Neutral/Positive -> focus, link, err/warn/ok
#    [WM] active/inactiveForeground -> testo titlebar attivo/inattivo
#  I grigi degli stati "disabilitato" restano quelli standard di Darkly.
#
#  Uso:    bash darklyoled-gtk.sh
#  Prereq: tema "Darkly" gia' installato (per i widget + asset GTK2/3).
#  Sicuro: backup .bak-TIMESTAMP di ogni file toccato.
# =============================================================================

set -euo pipefail

# ---- Configurazione ----------------------------------------------------------
THEME_DIR_NAME="Darkly-OLED"
THEME_DISPLAY_NAME="Darkly (OLED)"
APPLY=1                               # 1 = applica anche alla config (consigliato)

COLORS_FILE="$HOME/.local/share/color-schemes/DarklyOLED.colors"
DEST="$HOME/.local/share/themes/$THEME_DIR_NAME"
CFG3="$HOME/.config/gtk-3.0"
CFG4="$HOME/.config/gtk-4.0"
GRC2="$HOME/.gtkrc-2.0"
TS="$(date +%Y%m%d-%H%M%S)"

# ---- Utility -----------------------------------------------------------------
ini_get() { # $1=section  $2=key
  awk -v sec="$1" -v key="$2" '
    { sub(/\r$/,"") }
    /^\[/ { l=$0; gsub(/[ \t]/,"",l); in_sec=(l=="[" sec "]"); next }
    { e=index($0,"="); if(e==0) next
      k=substr($0,1,e-1); v=substr($0,e+1)
      gsub(/^[ \t]+|[ \t]+$/,"",k); gsub(/^[ \t]+|[ \t]+$/,"",v)
      if(in_sec && k==key){ print v; exit } }
  ' "$COLORS_FILE"
}
req() { local out; out="$(ini_get "$1" "$2")"
  [ -n "$out" ] || { echo "!! Manca [$1] $2 in $COLORS_FILE" >&2; exit 1; }; printf '%s' "$out"; }
rgb2hex() { local r g b; IFS=',' read -r r g b <<< "$1"
  printf '#%02x%02x%02x' "${r// /}" "${g// /}" "${b// /}"; }
backup() { [ -f "$1" ] && cp -a "$1" "$1.bak-$TS" && echo "   backup: $1.bak-$TS" || true; }
set_ini_key() { local file="$1" key="$2" val="$3"
  if [ ! -f "$file" ]; then printf '[Settings]\n%s=%s\n' "$key" "$val" > "$file"; return; fi
  if grep -q "^${key}=" "$file"; then sed -i "s|^${key}=.*|${key}=${val}|" "$file"
  elif grep -q '^\[Settings\]' "$file"; then sed -i "/^\[Settings\]/a ${key}=${val}" "$file"
  else printf '[Settings]\n%s=%s\n' "$key" "$val" >> "$file"; fi
}

# ---- 0. Controlli ------------------------------------------------------------
[ -f "$COLORS_FILE" ] || { echo "!! Palette non trovata: $COLORS_FILE"; exit 1; }
BASE=""
for d in "$HOME/.local/share/themes/Darkly" "$HOME/.themes/Darkly" \
         "/usr/local/share/themes/Darkly" "/usr/share/themes/Darkly"; do
  [ -d "$d/gtk-3.0" ] && { BASE="$d"; break; }
done
[ -n "$BASE" ] || { echo "!! Tema 'Darkly' non installato."; exit 1; }
echo ">> Palette:   $COLORS_FILE"
echo ">> Base:      $BASE"

# ---- 1. Estrai i colori dalla palette ---------------------------------------
WINDOW_BG=$(rgb2hex "$(req Colors:Window    BackgroundNormal)")
WINDOW_FG=$(rgb2hex "$(req Colors:Window    ForegroundNormal)")
VIEW_BG=$(rgb2hex   "$(req Colors:View      BackgroundNormal)")
VIEW_FG=$(rgb2hex   "$(req Colors:View      ForegroundNormal)")
BUTTON_BG=$(rgb2hex "$(req Colors:Button    BackgroundNormal)")
BUTTON_FG=$(rgb2hex "$(req Colors:Button    ForegroundNormal)")
SEL_BG=$(rgb2hex    "$(req Colors:Selection BackgroundNormal)")
SEL_FG=$(rgb2hex    "$(req Colors:Selection ForegroundNormal)")
TIP_BG=$(rgb2hex    "$(req Colors:Tooltip   BackgroundNormal)")
TIP_FG=$(rgb2hex    "$(req Colors:Tooltip   ForegroundNormal)")
DECO_FOCUS=$(rgb2hex "$(req Colors:Selection DecorationFocus)")
DECO_HOVER=$(rgb2hex "$(req Colors:Selection DecorationHover)")
LINK=$(rgb2hex    "$(req Colors:View ForegroundLink)")
VISITED=$(rgb2hex "$(req Colors:View ForegroundVisited)")
NEG=$(rgb2hex     "$(req Colors:View ForegroundNegative)")
NEU=$(rgb2hex     "$(req Colors:View ForegroundNeutral)")
POS=$(rgb2hex     "$(req Colors:View ForegroundPositive)")
TB_BG=$(rgb2hex          "$(req WM activeBackground)")
TB_FG=$(rgb2hex          "$(req WM activeForeground)")
TB_FG_INACTIVE=$(rgb2hex "$(req WM inactiveForeground)")

echo ">> Colori: finestre/viste $WINDOW_BG/$VIEW_BG  bottoni $BUTTON_BG  accento $SEL_BG"

# ---- 2a. colors.css (GTK3/GTK4) ---------------------------------------------
emit_colors() {
cat <<EOF
/* Darkly (OLED) - colors.css generato da DarklyOLED.colors ($TS) */
@define-color borders_breeze #3c3c3c;
@define-color content_view_bg_breeze $VIEW_BG;
@define-color error_color_backdrop_breeze $NEG;
@define-color error_color_breeze $NEG;
@define-color error_color_insensitive_backdrop_breeze #7d4e53;
@define-color error_color_insensitive_breeze #7d4e53;
@define-color insensitive_base_color_breeze #242424;
@define-color insensitive_base_fg_color_breeze #8b8b8b;
@define-color insensitive_bg_color_breeze #242424;
@define-color insensitive_borders_breeze #3e3e3e;
@define-color insensitive_fg_color_breeze #8b8b8b;
@define-color insensitive_selected_bg_color_breeze #242424;
@define-color insensitive_selected_fg_color_breeze #8b8b8b;
@define-color insensitive_unfocused_bg_color_breeze #242424;
@define-color insensitive_unfocused_fg_color_breeze #8b8b8b;
@define-color insensitive_unfocused_selected_bg_color_breeze #242424;
@define-color insensitive_unfocused_selected_fg_color_breeze #8b8b8b;
@define-color link_color_breeze $LINK;
@define-color link_visited_color_breeze $VISITED;
@define-color success_color_backdrop_breeze $POS;
@define-color success_color_breeze $POS;
@define-color success_color_insensitive_backdrop_breeze #4a745a;
@define-color success_color_insensitive_breeze #4a745a;
@define-color theme_base_color_breeze $VIEW_BG;
@define-color theme_bg_color_breeze $WINDOW_BG;
@define-color theme_button_background_backdrop_breeze $BUTTON_BG;
@define-color theme_button_background_backdrop_insensitive_breeze #242424;
@define-color theme_button_background_insensitive_breeze #242424;
@define-color theme_button_background_normal_breeze $BUTTON_BG;
@define-color theme_button_decoration_focus_backdrop_breeze $DECO_FOCUS;
@define-color theme_button_decoration_focus_backdrop_insensitive_breeze #475c79;
@define-color theme_button_decoration_focus_breeze $DECO_FOCUS;
@define-color theme_button_decoration_focus_insensitive_breeze #475c79;
@define-color theme_button_decoration_hover_backdrop_breeze $DECO_HOVER;
@define-color theme_button_decoration_hover_backdrop_insensitive_breeze #407289;
@define-color theme_button_decoration_hover_breeze $DECO_HOVER;
@define-color theme_button_decoration_hover_insensitive_breeze #407289;
@define-color theme_button_foreground_active_backdrop_breeze $WINDOW_FG;
@define-color theme_button_foreground_active_backdrop_insensitive_breeze #8b8b8b;
@define-color theme_button_foreground_active_breeze $BUTTON_FG;
@define-color theme_button_foreground_active_insensitive_breeze #8b8b8b;
@define-color theme_button_foreground_backdrop_breeze $BUTTON_FG;
@define-color theme_button_foreground_backdrop_insensitive_breeze #8b8b8b;
@define-color theme_button_foreground_insensitive_breeze #8b8b8b;
@define-color theme_button_foreground_normal_breeze $BUTTON_FG;
@define-color theme_fg_color_breeze $WINDOW_FG;
@define-color theme_header_background_backdrop_breeze $WINDOW_BG;
@define-color theme_header_background_breeze $WINDOW_BG;
@define-color theme_header_background_light_breeze $WINDOW_BG;
@define-color theme_header_foreground_backdrop_breeze $WINDOW_FG;
@define-color theme_header_foreground_breeze $WINDOW_FG;
@define-color theme_header_foreground_insensitive_backdrop_breeze $WINDOW_FG;
@define-color theme_header_foreground_insensitive_breeze $WINDOW_FG;
@define-color theme_hovering_selected_bg_color_breeze $DECO_HOVER;
@define-color theme_selected_bg_color_breeze $SEL_BG;
@define-color theme_selected_fg_color_breeze $SEL_FG;
@define-color theme_text_color_breeze $VIEW_FG;
@define-color theme_titlebar_background_backdrop_breeze $TB_BG;
@define-color theme_titlebar_background_breeze $TB_BG;
@define-color theme_titlebar_background_light_breeze $TB_BG;
@define-color theme_titlebar_foreground_backdrop_breeze $TB_FG_INACTIVE;
@define-color theme_titlebar_foreground_breeze $TB_FG;
@define-color theme_titlebar_foreground_insensitive_backdrop_breeze $TB_FG_INACTIVE;
@define-color theme_titlebar_foreground_insensitive_breeze $TB_FG_INACTIVE;
@define-color theme_unfocused_base_color_breeze $VIEW_BG;
@define-color theme_unfocused_bg_color_breeze $WINDOW_BG;
@define-color theme_unfocused_fg_color_breeze $WINDOW_FG;
@define-color theme_unfocused_selected_bg_color_alt_breeze #093047;
@define-color theme_unfocused_selected_bg_color_breeze #093047;
@define-color theme_unfocused_selected_fg_color_breeze $WINDOW_FG;
@define-color theme_unfocused_text_color_breeze $VIEW_FG;
@define-color theme_unfocused_view_bg_color_breeze #242424;
@define-color theme_unfocused_view_text_color_breeze #8b8b8b;
@define-color theme_view_active_decoration_color_breeze $DECO_HOVER;
@define-color theme_view_hover_decoration_color_breeze $DECO_HOVER;
@define-color tooltip_background_breeze $TIP_BG;
@define-color tooltip_border_breeze #4c4d4d;
@define-color tooltip_text_breeze $TIP_FG;
@define-color unfocused_borders_breeze #3c3c3c;
@define-color unfocused_insensitive_borders_breeze #3e3e3e;
@define-color warning_color_backdrop_breeze $NEU;
@define-color warning_color_breeze $NEU;
@define-color warning_color_insensitive_backdrop_breeze #8c6440;
@define-color warning_color_insensitive_breeze #8c6440;
EOF
}
COLORS_CSS="$(emit_colors)"

# ---- 2b. gtk-color-scheme (GTK2) --------------------------------------------
# Ruoli standard GTK2 (Murrine/Clearlooks/Adwaita li rispettano).
G2SCHEME="fg_color:$WINDOW_FG\nbg_color:$WINDOW_BG\nbase_color:$VIEW_BG\ntext_color:$VIEW_FG\nselected_bg_color:$SEL_BG\nselected_fg_color:$SEL_FG\ntooltip_bg_color:$TIP_BG\ntooltip_fg_color:$TIP_FG\nlink_color:$LINK"

# ---- 3. Crea il tema autonomo Darkly-OLED -----------------------------------
rm -rf "$DEST"
mkdir -p "$DEST/gtk-3.0" "$DEST/gtk-4.0"

# --- GTK3 ---
cp -a "$BASE/gtk-3.0/." "$DEST/gtk-3.0/"
[ -f "$DEST/gtk-3.0/gtk.css" ] && mv "$DEST/gtk-3.0/gtk.css" "$DEST/gtk-3.0/gtk-base.css"
printf '%s\n' "$COLORS_CSS" > "$DEST/gtk-3.0/colors.css"
printf "/* Darkly (OLED) */\n@import 'gtk-base.css';\n@import 'colors.css';\n" > "$DEST/gtk-3.0/gtk.css"
[ -f "$DEST/gtk-3.0/gtk-dark.css" ] && \
  printf "/* Darkly (OLED) */\n@import 'gtk-base.css';\n@import 'colors.css';\n" > "$DEST/gtk-3.0/gtk-dark.css"

# --- GTK4 ---
G4SRC=""
[ -f "$CFG4/gtk-darkly.css" ] && G4SRC="$CFG4"
[ -z "$G4SRC" ] && [ -f "$BASE/gtk-4.0/gtk-darkly.css" ] && G4SRC="$BASE/gtk-4.0"
if [ -n "$G4SRC" ]; then
  cp -a "$G4SRC/gtk-darkly.css" "$DEST/gtk-4.0/"
  [ -d "$G4SRC/darkly-gtk-assets" ] && cp -a "$G4SRC/darkly-gtk-assets" "$DEST/gtk-4.0/"
  [ -d "$G4SRC/assets" ]            && cp -a "$G4SRC/assets"            "$DEST/gtk-4.0/"
  printf '%s\n' "$COLORS_CSS" > "$DEST/gtk-4.0/colors.css"
  printf "/* Darkly (OLED) */\n@import 'gtk-darkly.css';\n@import 'colors.css';\n" > "$DEST/gtk-4.0/gtk.css"
else
  echo "!! gtk-darkly.css non trovato: salto la parte GTK4 del tema."
  rmdir "$DEST/gtk-4.0" 2>/dev/null || true
fi

# --- GTK2 ---
mkdir -p "$DEST/gtk-2.0"
if [ -d "$BASE/gtk-2.0" ]; then
  cp -a "$BASE/gtk-2.0/." "$DEST/gtk-2.0/"
  if [ -f "$DEST/gtk-2.0/gtkrc" ]; then
    mv "$DEST/gtk-2.0/gtkrc" "$DEST/gtk-2.0/gtkrc-base"
    { echo "# Darkly (OLED)"
      echo 'include "gtkrc-base"'
      printf 'gtk-color-scheme = "%s"\n' "$G2SCHEME"; } > "$DEST/gtk-2.0/gtkrc"
  else
    printf '# Darkly (OLED)\ngtk-color-scheme = "%s"\n' "$G2SCHEME" > "$DEST/gtk-2.0/gtkrc"
  fi
  echo ">> GTK2: widget dalla base + colori OLED."
else
  printf '# Darkly (OLED) - solo colori (Darkly non ha gtk-2.0)\ngtk-color-scheme = "%s"\n' "$G2SCHEME" > "$DEST/gtk-2.0/gtkrc"
  echo ">> GTK2: solo colori (base senza gtk-2.0)."
fi

cat > "$DEST/index.theme" <<IDX
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=$THEME_DISPLAY_NAME
Comment=Darkly con palette OLED derivata da DarklyOLED.colors
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=$THEME_DIR_NAME
IconTheme=Papirus-Dark
CursorTheme=material_dark_cursors
ButtonLayout=icon:minimize,maximize,close
IDX
echo ">> Tema creato in: $DEST"

# ---- 4. Applica alla config -------------------------------------------------
if [ "$APPLY" = "1" ]; then
  echo ">> Applico alla config (con backup):"
  mkdir -p "$CFG3" "$CFG4"

  # GTK3
  backup "$CFG3/colors.css"; backup "$CFG3/gtk.css"
  printf '%s\n' "$COLORS_CSS" > "$CFG3/colors.css"
  printf "@import 'colors.css';\n" > "$CFG3/gtk.css"

  # GTK4
  if [ ! -f "$CFG4/gtk-darkly.css" ] && [ -f "$DEST/gtk-4.0/gtk-darkly.css" ]; then
    cp -a "$DEST/gtk-4.0/gtk-darkly.css" "$CFG4/"
    [ -d "$DEST/gtk-4.0/darkly-gtk-assets" ] && cp -a "$DEST/gtk-4.0/darkly-gtk-assets" "$CFG4/"
    [ -d "$DEST/gtk-4.0/assets" ]            && cp -a "$DEST/gtk-4.0/assets"            "$CFG4/"
  fi
  backup "$CFG4/colors.css"; backup "$CFG4/gtk.css"
  printf '%s\n' "$COLORS_CSS" > "$CFG4/colors.css"
  if [ -f "$CFG4/gtk-darkly.css" ]; then
    printf "@import 'gtk-darkly.css';\n@import 'colors.css';\n" > "$CFG4/gtk.css"
  else
    printf "@import 'colors.css';\n" > "$CFG4/gtk.css"
  fi

  # Nome tema per GTK3/4 "pure"
  backup "$CFG3/settings.ini"; backup "$CFG4/settings.ini"
  set_ini_key "$CFG3/settings.ini" gtk-theme-name "$THEME_DIR_NAME"
  set_ini_key "$CFG4/settings.ini" gtk-theme-name "$THEME_DIR_NAME"
  command -v gsettings >/dev/null && \
    gsettings set org.gnome.desktop.interface gtk-theme "$THEME_DIR_NAME" 2>/dev/null || true

  # GTK2: ~/.gtkrc-2.0 (nome tema + gtk-color-scheme OLED, blocco idempotente)
  [ -f "$GRC2" ] && backup "$GRC2"
  touch "$GRC2"
  if grep -q '^[[:space:]]*gtk-theme-name' "$GRC2"; then
    sed -i "s|^[[:space:]]*gtk-theme-name.*|gtk-theme-name=\"$THEME_DIR_NAME\"|" "$GRC2"
  else
    printf 'gtk-theme-name="%s"\n' "$THEME_DIR_NAME" >> "$GRC2"
  fi
  sed -i '/# >>> Darkly-OLED colors >>>/,/# <<< Darkly-OLED colors <<</d' "$GRC2"
  { echo "# >>> Darkly-OLED colors >>>"
    printf 'gtk-color-scheme = "%s"\n' "$G2SCHEME"
    echo "# <<< Darkly-OLED colors <<<"; } >> "$GRC2"
fi

echo ""
echo "============================================================"
echo " Fatto.  Tema: $DEST"
if [ "$APPLY" = "1" ]; then
echo " Config aggiornata: ~/.gtkrc-2.0 (GTK2), ~/.config/gtk-3.0 e gtk-4.0."
echo ""
echo " Riavvia le app GTK (o logout/login) per vedere i neri anche su GTK2."
else
echo ""
echo " Applica con: gsettings set org.gnome.desktop.interface gtk-theme '$THEME_DIR_NAME'"
fi
echo " Backup .bak-$TS accanto a ogni file toccato."
echo "============================================================"
