#!/usr/bin/env bash
set -euo pipefail

# Ensure sudo is ready
source "$(dirname "$0")/libs/require-sudo.sh"

# # From here on, any sudo command runs without re-prompting
# sudo apt update
# sudo apt install -y git curl vim

# Sub-scripts can also source it — the guard prevents duplicate prompts/keepers
source "$(dirname "$0")/install-flatpak.sh"
source "$(dirname "$0")/install-snap.sh"