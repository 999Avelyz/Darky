# 🌙 Darkly OLED (KDE, Qt & GTK)

A complete step-by-step setup to get a **100% OLED Darkly theme (pure black)** across your entire system: KDE Plasma (Qt), GTK applications (2, 3, and 4), and Flatpak. 

This repository contains the custom `DarklyOLED.colors` palette and a dedicated Bash script to force absolute blacks even on GTK and Libadwaita software.

---

## 🚀 Step 0: Clone this repository
First, download the necessary files (the palette and the patcher script) from this repository to your local machine:

```bash
cd ~
git clone https://github.com/999Avely/Darkly-OLED.git
cd Darkly-OLED
```
*(Keep this terminal open or remember where this folder is, you will need these files later).*

---

## 📦 Step 1: Install Dependencies (Debian/Ubuntu)
Before building the themes, make sure you have all the necessary dependencies installed. Run this in your terminal:

```bash
sudo apt update
sudo apt install \
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
    libkirigami-dev
```

---

## 🎨 Step 2: Darkly for KDE/Qt (The Core Theme)

### 2.1 Download and build Darkly Qt
Download the original Darkly engine source code and install it:

```bash
cd ~
git clone https://github.com/Bali10050/Darkly
cd Darkly
./install.sh
```

### 2.2 Apply the OLED Palette
Now, we need to apply the pure black palette provided in this repository.

**Method A: Via Terminal (Fastest)**
```bash
cd ~/Darkly-OLED
cp DarklyOLED.colors ~/.local/share/color-schemes/
```
Once copied, open **System Settings → Colors**, select **DarklyOLED**, and click **Apply**.

**Method B: Via GUI**
1. Open **System Settings** → **Colors**.
2. Click the **"Install from file..."** button (bottom right).
3. Navigate to `~/Darkly-OLED` and select `DarklyOLED.colors`.
4. Select it from the list and click **Apply**.

---

## 🖌️ Step 3: Apply OLED to GTK Apps (2/3/4)

The base Darkly theme for GTK uses dark gray backgrounds. To get pure OLED blacks, we will install the official GTK port and then patch it with our script.

### 3.1 Download and install Darkly GTK
```bash
cd ~
git clone https://github.com/wrymt/darkly-gtk
cd darkly-gtk
./install.sh
```

### 3.2 Generate and apply the Darkly-OLED patch
To force pure black on GTK2, GTK3, and GTK4 (including Libadwaita), run the script provided in this repository:

```bash
cd ~/Darkly-OLED
bash DarklyOLED-GTK.sh
```
This script will read your active `DarklyOLED.colors` palette and automatically create/apply a standalone OLED theme to all your GTK configuration folders. 
*(Note: You may need to close and reopen your GTK apps or log out/log in to see the changes).*

---

## 📦 Step 4: Flatpak Configuration

Flatpak apps are sandboxed and need special permissions, as well as a specific Flatpak version of the Darkly theme, to match your system look.

### 4.1 Download and Install Darkly for Flatpak
Download the pre-compiled `.flatpak` file and install it globally:

```bash
cd ~
wget https://github.com/Bali10050/Darkly/releases/download/v0.5.38/darkly-qt6.9-0.5.38-x86_64.flatpak
flatpak install darkly-qt6.9-0.5.38-x86_64.flatpak
```

### 4.2 Grant permissions to Flatpak apps
You need to tell Flatpak apps to use the new theme and allow them to read the configuration files.

**Option A: Via Terminal (CLI Method)**
Run these commands to apply the overrides globally:
```bash
# Allow Flatpaks to read system themes and GTK4 config (Libadwaita)
sudo flatpak override --filesystem=xdg-data/themes
sudo flatpak override --filesystem=xdg-config/gtk-4.0

# Allow reading Darkly Qt config and set the required environment variables
sudo flatpak override --filesystem=xdg-config/darklyrc:ro
sudo flatpak override --env=QT_STYLE_OVERRIDE=Darkly
sudo flatpak override --env=QT_QPA_PLATFORMTHEME=kde
```

**Option B: Via Flatseal (GUI Method)**
1. Open **Flatseal** and select **All Applications** (top left).
2. Scroll down to **Filesystem** → **Other files** and add:
   - `xdg-data/themes`
   - `xdg-config/gtk-4.0`
   - `xdg-config/darklyrc:ro`
3. Scroll down to **Environment** and add:
   - `QT_STYLE_OVERRIDE=Darkly`
   - `QT_QPA_PLATFORMTHEME=kde`

---
*Enjoy your full OLED system!*
