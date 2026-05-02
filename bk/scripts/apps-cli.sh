#!/usr/bin/env bash
# RUN_AS: root
# apps-cli.sh — CLI essentials for a NixOS-feeling shell on Debian
#
# Installs:
#   - zsh + autosuggestions + syntax highlighting + history substring search
#   - zoxide (smart `cd` replacement)
#   - vim, neovim
#   - fastfetch (system info on shell startup, replaces neofetch)
#   - curl, wget, git, ssh client
#   - fzf, ripgrep, fd, bat, eza (modern unix tools)
#   - btop, htop (system monitors)
#   - tree, jq, yq, unzip, zip
#   - direnv (per-directory env vars)
#   - tmux
#   - starship (prompt)
#
# After running: open a new terminal or `exec zsh` to use the new shell.

set -euo pipefail

[ "$EUID" -eq 0 ] || { echo "run as root: sudo $0"; exit 1; }
REAL_USER="${SUDO_USER:-$(logname)}"
[ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ] || {
  echo "run via sudo, not as root login"; exit 1; }

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
say()  { echo "${BLUE}==>${NC} $*"; }
ok()   { echo "${GREEN}[ok]${NC} $*"; }
warn() { echo "${YELLOW}[warn]${NC} $*" >&2; }

# ---- 1. core CLI tools via apt ---------------------------------------------
say "Installing CLI essentials via apt..."

apt update

apt install -y \
  zsh \
  zsh-autosuggestions \
  zsh-syntax-highlighting \
  zsh-doc \
  zoxide \
  vim \
  neovim \
  fastfetch \
  curl \
  wget \
  git \
  openssh-client \
  fzf \
  ripgrep \
  fd-find \
  bat \
  eza \
  btop \
  htop \
  tree \
  jq \
  unzip \
  zip \
  direnv \
  tmux \
  yq \
  ncdu \
  tealdeer \
  ca-certificates

ok "core CLI tools installed"

# ---- 2. starship prompt ----------------------------------------------------
# starship is in apt on Debian 13 (Trixie). On older Debian, fall back to
# the official installer. We try apt first.
say "Installing starship prompt..."

if apt-cache show starship >/dev/null 2>&1; then
  apt install -y starship
  ok "starship installed via apt"
else
  warn "starship not in apt — using official installer"
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
  ok "starship installed via upstream"
fi

# ---- 3. set zsh as default shell for the user ------------------------------
CURRENT_SHELL="$(getent passwd "$REAL_USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" != "/usr/bin/zsh" ] && [ "$CURRENT_SHELL" != "/bin/zsh" ]; then
  say "Setting zsh as default shell for $REAL_USER..."
  chsh -s /usr/bin/zsh "$REAL_USER"
  ok "zsh is now the default shell (effective on next login)"
else
  ok "zsh already the default shell"
fi

# ---- 4. tldr cache (offline man-page summaries) ----------------------------
say "Updating tldr cache for $REAL_USER..."
sudo -u "$REAL_USER" tldr --update >/dev/null 2>&1 || warn "tldr cache update skipped"

# ---- 5. summary -----------------------------------------------------------
echo
ok "=== apps-cli.sh complete ==="
echo
cat <<EOF
Installed:
  ${BLUE}zsh${NC}              shell — log out and back in to use it
  ${BLUE}starship${NC}         prompt — auto-activates if .zshrc has eval line
  ${BLUE}zoxide${NC}           smart cd  — usage: ${YELLOW}z <partial-name>${NC}
  ${BLUE}vim, neovim${NC}      editors
  ${BLUE}fastfetch${NC}        system info — try ${YELLOW}fastfetch${NC}
  ${BLUE}fzf${NC}              fuzzy finder — Ctrl-R for history search
  ${BLUE}ripgrep${NC}          fast grep — usage: ${YELLOW}rg <pattern>${NC}
  ${BLUE}fd-find${NC}          fast find — usage: ${YELLOW}fdfind <name>${NC} (or alias fd)
  ${BLUE}bat${NC}              cat with syntax highlighting — Debian calls it ${YELLOW}batcat${NC}
  ${BLUE}eza${NC}              modern ls
  ${BLUE}btop, htop${NC}       system monitors
  ${BLUE}tldr${NC}             concise man pages — ${YELLOW}tldr <command>${NC}
  ${BLUE}direnv${NC}           per-dir environment — needs hook in shell rc
  ${BLUE}tmux${NC}             terminal multiplexer

Next: run ${YELLOW}03-dotfiles.sh${NC} to get the curated zsh/kitty/git config.
EOF
