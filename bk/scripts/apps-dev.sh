#!/usr/bin/env bash
# RUN_AS: root
# apps-dev.sh — development environment
#
# Installs:
#   - flatpak + flathub remote
#   - build-essential (gcc, make, etc.)
#   - python3, pip, pipx, python venv
#   - nvs (Node Version Switcher) for the user
#   - Node.js 22 via nvs
#   - Common dev tools: gh (GitHub CLI), docker, docker-compose

set -euo pipefail

[ "$EUID" -eq 0 ] || { echo "run as root: sudo $0"; exit 1; }
REAL_USER="${SUDO_USER:-$(logname)}"
[ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ] || {
  echo "run via sudo, not as root login"; exit 1; }
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
say()  { echo "${BLUE}==>${NC} $*"; }
ok()   { echo "${GREEN}[ok]${NC} $*"; }
warn() { echo "${YELLOW}[warn]${NC} $*" >&2; }

apt update

# ---- 1. flatpak ------------------------------------------------------------
say "Installing flatpak + flathub..."
apt install -y flatpak

# Add flathub remote (system-wide). --if-not-exists makes it idempotent.
flatpak remote-add --if-not-exists flathub \
  https://dl.flathub.org/repo/flathub.flatpakrepo

# GNOME plugin makes flatpaks show in GNOME Software (only matters if GNOME
# is installed; harmless otherwise)
apt install -y gnome-software-plugin-flatpak 2>/dev/null || true

ok "flatpak ready"

# ---- 2. build-essential (compilers, make) ----------------------------------
say "Installing build-essential..."
apt install -y \
  build-essential \
  pkg-config \
  cmake \
  meson \
  ninja-build \
  autoconf \
  automake \
  libtool
ok "build tools installed"

# ---- 3. Python --------------------------------------------------------------
say "Installing Python toolchain..."
apt install -y \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  python3-setuptools \
  python3-wheel \
  pipx

# Make pipx's bin path available
sudo -u "$REAL_USER" pipx ensurepath >/dev/null 2>&1 || true

ok "Python installed"
echo "  ${YELLOW}Note${NC}: Debian's Python is system-managed."
echo "        Use ${BLUE}pipx install <tool>${NC} for global Python CLI tools."
echo "        Use ${BLUE}python3 -m venv .venv${NC} for project-specific environments."

# ---- 4. nvs (Node Version Switcher) ----------------------------------------
# nvs is a node-based version manager. We install it for the user, then use
# it to install Node 22.
#
# nvs lives under ~/.nvs, sources via ~/.nvs/nvs.sh in the user's shell rc.
say "Installing nvs (Node Version Switcher) for $REAL_USER..."

NVS_DIR="$REAL_HOME/.nvs"
if [ ! -d "$NVS_DIR" ]; then
  sudo -u "$REAL_USER" git clone --branch v1.7.1 --depth 1 \
    https://github.com/jasongin/nvs "$NVS_DIR"

  # Initial bootstrap: generates the nvs cache/lookup tables
  sudo -u "$REAL_USER" -H bash -c "
    export NVS_HOME='$NVS_DIR'
    . '$NVS_DIR/nvs.sh' install
  "
  ok "nvs installed at $NVS_DIR"
else
  ok "nvs already installed at $NVS_DIR"
fi

# ---- 5. Node 22 via nvs ----------------------------------------------------
say "Installing Node.js 22 via nvs..."
sudo -u "$REAL_USER" -H bash -c "
  export NVS_HOME='$NVS_DIR'
  . '$NVS_DIR/nvs.sh'
  nvs add 22
  nvs link 22
" || warn "nvs node 22 install hit an issue — try manually:  nvs add 22 && nvs link 22"

ok "Node 22 installed (via nvs)"

# Append nvs init to ~/.zshrc and ~/.bashrc if not already there
say "Wiring nvs into shell rc files..."
NVS_INIT_BLOCK='
# nvs (Node Version Switcher)
export NVS_HOME="$HOME/.nvs"
[ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh"
'

for rc in "$REAL_HOME/.zshrc" "$REAL_HOME/.bashrc"; do
  if [ -f "$rc" ] && ! grep -q "NVS_HOME" "$rc"; then
    echo "$NVS_INIT_BLOCK" | sudo -u "$REAL_USER" tee -a "$rc" >/dev/null
    ok "added nvs init to $(basename "$rc")"
  fi
done

# ---- 6. GitHub CLI ---------------------------------------------------------
say "Installing GitHub CLI (gh)..."
if ! command -v gh >/dev/null 2>&1; then
  # Add the GitHub CLI repo (official)
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
  apt update
fi
apt install -y gh
ok "gh installed (run ${YELLOW}gh auth login${NC} as your user to authenticate)"

# ---- 7. Docker -------------------------------------------------------------
say "Installing Docker..."

# Use Debian's docker.io package (simpler than Docker Inc's repo for personal use)
apt install -y docker.io docker-compose

# Add user to docker group so they don't need sudo for docker commands
if ! groups "$REAL_USER" | grep -qw docker; then
  usermod -aG docker "$REAL_USER"
  ok "added $REAL_USER to docker group (effective on next login)"
fi

systemctl enable --now docker
ok "Docker ready"

# ---- 8. summary ------------------------------------------------------------
echo
ok "=== apps-dev.sh complete ==="
echo
cat <<EOF
Installed:
  ${BLUE}flatpak${NC} + flathub      ${YELLOW}flatpak install flathub <app>${NC}
  ${BLUE}build-essential${NC}        gcc, make, cmake, meson, etc.
  ${BLUE}python3${NC} + pipx          ${YELLOW}pipx install <tool>${NC} for global CLI tools
  ${BLUE}nvs${NC}                    Node Version Switcher at ${YELLOW}~/.nvs${NC}
  ${BLUE}node 22${NC}                via nvs (linked as default)
  ${BLUE}gh${NC}                     GitHub CLI — ${YELLOW}gh auth login${NC} to authenticate
  ${BLUE}docker${NC} + compose        added you to docker group (re-login required)

Open a new terminal to pick up:
  - the docker group membership (so you don't need sudo for docker)
  - nvs init (so 'node', 'npm' work without sourcing manually)

Verify:
  ${BLUE}node --version${NC}    # should print v22.x
  ${BLUE}python3 --version${NC}
  ${BLUE}docker run hello-world${NC}
EOF
