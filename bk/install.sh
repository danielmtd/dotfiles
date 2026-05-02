#!/usr/bin/env bash
# install.sh — main interactive menu for Debian P52 setup
#
# Categories:
#   1) Drivers           → 01-base.sh + the standalone NVIDIA installer
#   2) Apps              → CLI tools, dev environment, GUI apps
#   3) Compositor (DMS)  → niri + DankMaterialShell
#   4) Dotfiles          → zsh/kitty/yazi/git/etc config
#   5) Snapshots         → Timeshift setup
#   6) Update            → daily update wrapper
#
# Run with no args for the menu. Or use flags: --drivers, --apps, --dms, etc.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; NC=$'\033[0m'

say()  { echo "${BLUE}==>${NC} $*"; }
ok()   { echo "${GREEN}[ok]${NC} $*"; }
warn() { echo "${YELLOW}[warn]${NC} $*" >&2; }
err()  { echo "${RED}[err]${NC} $*" >&2; exit 1; }

# Run a sub-script, sudo-elevating if it expects root, plain otherwise.
# We use the shebang of the script + a comment convention "# RUN_AS: root|user"
run_script() {
  local script="$1"; shift || true
  [ -f "$script" ] || err "script not found: $script"
  [ -x "$script" ] || chmod +x "$script"

  local run_as="root"
  if grep -qE '^# RUN_AS:[[:space:]]*user' "$script"; then
    run_as="user"
  fi

  if [ "$run_as" = "root" ]; then
    if [ "$EUID" -eq 0 ]; then
      "$script" "$@"
    else
      sudo "$script" "$@"
    fi
  else
    if [ "$EUID" -eq 0 ]; then
      err "$script must be run as your normal user, not root"
    fi
    "$script" "$@"
  fi
}

# ============================================================
# Drivers menu
# ============================================================
drivers_menu() {
  while true; do
    cat <<EOF

${BOLD}╔════════════════════════════════════════════════╗${NC}
${BOLD}║  Drivers & base system                         ║${NC}
${BOLD}╚════════════════════════════════════════════════╝${NC}

  ${BOLD}1${NC}) Base system setup       — apt sources, fonts, audio, TLP, fwupd
  ${BOLD}2${NC}) NVIDIA driver           — interactive installer (this is the
                                full Dennis Hilk script — your choice of
                                stable / backports / nouveau / remove)
  ${BOLD}3${NC}) Both, in order          — base then NVIDIA

  ${BOLD}b${NC}) Back to main menu

EOF
    read -rp "Selection: " sel
    case "$sel" in
      1) run_script "$SCRIPTS_DIR/01-base.sh" ;;
      2) run_script "$SCRIPTS_DIR/nvidia-installer.sh" ;;
      3)
        run_script "$SCRIPTS_DIR/01-base.sh"
        echo
        warn "01-base.sh complete. Run NVIDIA installer now? (recommended)"
        read -rp "[Y/n] " yn
        [[ ! "$yn" =~ ^[Nn]$ ]] && run_script "$SCRIPTS_DIR/nvidia-installer.sh"
        ;;
      b|B) return ;;
      *) warn "unknown option" ;;
    esac
    echo; read -rp "Press Enter to continue..." _
  done
}

# ============================================================
# Apps menu
# ============================================================
apps_menu() {
  while true; do
    cat <<EOF

${BOLD}╔════════════════════════════════════════════════╗${NC}
${BOLD}║  Applications                                  ║${NC}
${BOLD}╚════════════════════════════════════════════════╝${NC}

  ${BOLD}1${NC}) CLI essentials         — zsh, zoxide, vim, fastfetch, curl,
                                git, fzf, ripgrep, bat, fd, btop
  ${BOLD}2${NC}) Dev environment        — flatpak, nvs + node 22, Python 3
                                + pipx + pyenv basics, build-essential
  ${BOLD}3${NC}) GUI applications       — Parsec, Thorium browser, VSCode
  ${BOLD}4${NC}) All three, in order

  ${BOLD}b${NC}) Back to main menu

EOF
    read -rp "Selection: " sel
    case "$sel" in
      1) run_script "$SCRIPTS_DIR/apps-cli.sh" ;;
      2) run_script "$SCRIPTS_DIR/apps-dev.sh" ;;
      3) run_script "$SCRIPTS_DIR/apps-gui.sh" ;;
      4)
        run_script "$SCRIPTS_DIR/apps-cli.sh"
        run_script "$SCRIPTS_DIR/apps-dev.sh"
        run_script "$SCRIPTS_DIR/apps-gui.sh"
        ;;
      b|B) return ;;
      *) warn "unknown option" ;;
    esac
    echo; read -rp "Press Enter to continue..." _
  done
}

# ============================================================
# Main menu
# ============================================================
main_menu() {
  while true; do
    cat <<EOF

${BOLD}╔════════════════════════════════════════════════════════╗${NC}
${BOLD}║  Debian P52 management                                 ║${NC}
${BOLD}╠════════════════════════════════════════════════════════╣${NC}

  ${CYAN}Setup${NC}
    ${BOLD}1${NC}) Drivers           — base system + NVIDIA installer
    ${BOLD}2${NC}) Apps              — CLI / dev environment / GUI apps
    ${BOLD}3${NC}) Compositor (DMS)  — niri + DankMaterialShell
    ${BOLD}4${NC}) Dotfiles          — zsh/kitty/yazi/git config

  ${CYAN}Maintenance${NC}
    ${BOLD}5${NC}) Snapshots         — Timeshift setup (rollback safety net)
    ${BOLD}6${NC}) Update            — apt + flatpak + firmware

    ${BOLD}q${NC}) Quit

${BOLD}╚════════════════════════════════════════════════════════╝${NC}

EOF
    read -rp "Selection: " sel
    case "$sel" in
      1) drivers_menu ;;
      2) apps_menu ;;
      3) run_script "$SCRIPTS_DIR/02-niri-dms.sh" ;;
      4) run_script "$SCRIPTS_DIR/03-dotfiles.sh" ;;
      5) run_script "$SCRIPTS_DIR/04-timeshift.sh" ;;
      6) run_script "$SCRIPTS_DIR/update.sh" ;;
      q|Q) exit 0 ;;
      *) warn "unknown option: $sel" ;;
    esac
  done
}

# ============================================================
# CLI flag shortcuts (bypass menu)
# ============================================================
case "${1:-menu}" in
  --help|-h)
    cat <<EOF
Usage: $0 [option]

Options:
  --drivers       run drivers menu
  --apps          run apps menu
  --apps-cli      install CLI essentials only
  --apps-dev      install dev environment only
  --apps-gui      install GUI apps only
  --dms           install niri + DMS
  --dotfiles      apply zsh/kitty/yazi/git dotfiles
  --update        run update wrapper
  --snapshots     set up Timeshift
  (no args)       interactive menu
EOF
    exit 0
    ;;
  --drivers)   drivers_menu ;;
  --apps)      apps_menu ;;
  --apps-cli)  run_script "$SCRIPTS_DIR/apps-cli.sh" ;;
  --apps-dev)  run_script "$SCRIPTS_DIR/apps-dev.sh" ;;
  --apps-gui)  run_script "$SCRIPTS_DIR/apps-gui.sh" ;;
  --dms)       run_script "$SCRIPTS_DIR/02-niri-dms.sh" ;;
  --dotfiles)  run_script "$SCRIPTS_DIR/03-dotfiles.sh" ;;
  --update)    run_script "$SCRIPTS_DIR/update.sh" ;;
  --snapshots) run_script "$SCRIPTS_DIR/04-timeshift.sh" ;;
  menu|"")     main_menu ;;
  *)           err "unknown argument: $1 (try --help)" ;;
esac
