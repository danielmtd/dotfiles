#!/usr/bin/env bash
set -euo pipefail

# Ensure sudo is ready
source "$(dirname "$0")/libs/sudo.sh"

# sources
# sudo cp ./sources/debian-backports.sources /etc/apt/sources.list.d/
sudo cp ./sources/corectrl /etc/apt/preferences.d
sudo apt update

# drivers
source "$(dirname "$0")/apps/radeon.sh"

# # Sub-scripts can also source it — the guard prevents duplicate prompts/keepers
source "$(dirname "$0")/apps/thorium.sh"
source "$(dirname "$0")/apps/vscode.sh"
source "$(dirname "$0")/apps/_packages.sh"
source "$(dirname "$0")/apps/cli.sh"
source "$(dirname "$0")/apps/kitty-update.sh"
./apps/dotfiles.sh

# niri config
cp -r "./config/niri" "${HOME}/.config"
cp "./config/code-flags.conf" "${HOME}/.config"

# additional configs
cp -r ./config/kitty ~/.config

# stuff we need
source "$(dirname "$0")/apps/nvm.sh"
source "$(dirname "$0")/apps/nvs.sh"


