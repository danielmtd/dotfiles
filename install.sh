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

# niri config
cp -r "./config/niri" "${HOME}/.config"
cp "./config/code-flags.conf" "${HOME}/.config"

# # source "$(dirname "$0")/install-snap.shs