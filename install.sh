#!/usr/bin/env bash
set -euo pipefail

# Ensure sudo is ready
source "$(dirname "$0")/libs/sudo.sh"
# 
# # # From here on, any sudo command runs without re-prompting
sudo apt update
# # sudo apt install -y git curl vim
# 
# # Sub-scripts can also source it — the guard prevents duplicate prompts/keepers
# source "$(dirname "$0")/apps/thorium.sh"
# source "$(dirname "$0")/apps/vscode.sh"
# source "$(dirname "$0")/apps/_packages.sh"
# source "$(dirname "$0")/apps/cli.sh"
# ./apps/dotfiles.sh


# niri config
# cp -r "./config/niri" "${HOME}/.config"
# cp "./config/code-flags.conf" "${HOME}/.config"

# additional configs

# cp -r ./config/kitty ~/.config

# # source "$(dirname "$0")/install-snap.shs

# needs to be done in the end
# source "$(dirname "$0")/apps/nvm.sh"
# source "$(dirname "$0")/apps/nvs.sh"