#!/usr/bin/env bash
#
# setup.sh — install apt and flatpak packages with a single sudo prompt
#
set -euo pipefail

# --- 1. Ask for sudo upfront ---------------------------------------------------
echo "==> This script needs sudo. You'll be prompted once."
sudo -v || { echo "sudo required, exiting."; exit 1; }

# Keep sudo timestamp alive in the background until the script ends
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
SUDO_KEEPER_PID=$!
trap 'kill "$SUDO_KEEPER_PID" 2>/dev/null || true' EXIT

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
    com.spotify.Client
    org.mozilla.firefox
    com.discordapp.Discord
    org.videolan.VLC
    org.gimp.GIMP
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