#!/usr/bin/env bash

# --- 2. APT packages -----------------------------------------------------------
APT_PACKAGES=(
    git
    curl
    wget
    vim
    htop
    build-essential
    ca-certificates
    gnupg
    flatpak
)

echo "==> Updating apt..."
sudo apt update
sudo apt upgrade -y

echo "==> Installing apt packages..."
sudo apt install -y "${APT_PACKAGES[@]}"

# --- 3. Flatpak setup + packages ----------------------------------------------
FLATPAK_PACKAGES=(
    com.parsecgaming.parsec
    org.mozilla.firefox
    org.videolan.VLC
)

echo "==> Adding Flathub remote (if missing)..."
sudo flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo

echo "==> Installing flatpak packages..."
for pkg in "${FLATPAK_PACKAGES[@]}"; do
    sudo flatpak install -y flathub "$pkg"
done

# --- 4. Cleanup ----------------------------------------------------------------
echo "==> Cleaning up..."
sudo apt autoremove -y
sudo apt clean

echo "==> Done!"