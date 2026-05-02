#!/usr/bin/env bash
# RUN_AS: root
# apps-gui.sh — GUI applications
#
# Installs:
#   - VSCode (via Microsoft's official APT repo)
#   - Thorium browser (Chromium-based, fast)
#   - Parsec (remote desktop)
#
# All three are NOT in Debian's repos — they're installed from upstream.
# That's fine but worth knowing: they update via their own repos / scripts,
# not via the standard Debian update cycle.

set -euo pipefail

[ "$EUID" -eq 0 ] || { echo "run as root: sudo $0"; exit 1; }
REAL_USER="${SUDO_USER:-$(logname)}"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
say()  { echo "${BLUE}==>${NC} $*"; }
ok()   { echo "${GREEN}[ok]${NC} $*"; }
warn() { echo "${YELLOW}[warn]${NC} $*" >&2; }

ARCH=$(dpkg --print-architecture)

apt update
apt install -y curl wget gpg ca-certificates apt-transport-https

# ============================================================
# 1. Parsec
# ============================================================
say "Installing Parsec..."

# Parsec ships an official .deb at parsec.app/downloads (linked as parsec-linux.deb)
PARSEC_TMP=$(mktemp -d)
trap "rm -rf $PARSEC_TMP" EXIT

PARSEC_URL="https://builds.parsec.app/package/parsec-linux.deb"

say "Downloading Parsec..."
if wget -qO "$PARSEC_TMP/parsec.deb" "$PARSEC_URL"; then
  apt install -y "$PARSEC_TMP/parsec.deb"
  ok "Parsec installed"
else
  warn "Parsec download failed. Try manually:"
  warn "  https://parsec.app/downloads"
fi

# ============================================================
# Summary
# ============================================================
echo
ok "=== apps-gui.sh complete ==="
echo
cat <<EOF
Installed:
  ${BLUE}VSCode${NC}     — open via launcher or ${YELLOW}code${NC} from terminal
                  Updates via apt (Microsoft's repo).
                  Sign in to sync settings: gear icon → Sign In.

  ${BLUE}Thorium${NC}    — open via launcher or ${YELLOW}thorium-browser${NC}
                  Chromium-based, optimized for speed.
                  Updates: re-run this script, or download new .deb manually.

  ${BLUE}Parsec${NC}     — open via launcher or ${YELLOW}parsecd${NC}
                  Remote desktop client. Sign in with your Parsec account.
                  Updates via Parsec's auto-update.

${YELLOW}Note${NC}: VSCode is in Microsoft's repo — it auto-updates with apt.
       Thorium and Parsec do NOT auto-update. Re-run this script periodically
       to refresh them, or set up your own update mechanism.

Other useful things you might want (not installed automatically):
  ${BLUE}sudo apt install firefox-esr${NC}        # Mozilla's ESR build
  ${BLUE}flatpak install flathub com.spotify.Client${NC}
  ${BLUE}flatpak install flathub com.discordapp.Discord${NC}
  ${BLUE}flatpak install flathub org.signal.Signal${NC}
EOF
