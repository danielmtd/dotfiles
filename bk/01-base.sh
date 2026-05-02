#!/usr/bin/env bash
# RUN_AS: root
# 01-base.sh — Debian P52 base setup
#
# Run AFTER the Debian installer has put a working base system on disk
# and you've verified `sudo` works for your user.
#
# Idempotent: re-running won't break anything; it just re-applies state.

set -euo pipefail

# ---- guards -----------------------------------------------------------------
[ "$EUID" -eq 0 ] || { echo "run as root: sudo $0"; exit 1; }
[ -f /etc/debian_version ] || { echo "this script is for Debian only"; exit 1; }

REAL_USER="${SUDO_USER:-$(logname)}"
[ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ] || {
  echo "couldn't determine the real user (run via sudo, not as root login)"; exit 1; }

# ---- pretty output ----------------------------------------------------------
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
say()  { echo "${BLUE}==>${NC} $*"; }
ok()   { echo "${GREEN}[ok]${NC} $*"; }
warn() { echo "${YELLOW}[warn]${NC} $*" >&2; }
err()  { echo "${RED}[err]${NC} $*" >&2; exit 1; }

# ---- 1. enable contrib + non-free + non-free-firmware -----------------------
# Required for NVIDIA drivers and some firmware
say "Enabling contrib, non-free, and non-free-firmware in apt sources..."

# Debian 12+ uses /etc/apt/sources.list.d/debian.sources (Deb822 format)
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
  if ! grep -q "non-free-firmware" /etc/apt/sources.list.d/debian.sources; then
    sed -i 's/^Components: main$/Components: main contrib non-free non-free-firmware/' \
      /etc/apt/sources.list.d/debian.sources
  fi
elif [ -f /etc/apt/sources.list ]; then
  # Older one-line format
  if ! grep -q "non-free-firmware" /etc/apt/sources.list; then
    sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
  fi
else
  err "couldn't find apt sources file to modify"
fi

apt update
ok "apt sources configured"

# ---- 2. system update -------------------------------------------------------
say "Updating system..."
DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
ok "system updated"

# ---- 3. base CLI tools ------------------------------------------------------
say "Installing base utilities..."
apt install -y \
  build-essential \
  curl wget \
  git \
  vim nano \
  htop btop \
  tree \
  unzip zip \
  pciutils usbutils \
  lshw \
  fwupd \
  rsync \
  ca-certificates \
  gnupg \
  software-properties-common \
  apt-transport-https
ok "base tools installed"

# Set vim as system-wide default editor (replaces nano).
# Affects: sudoedit, visudo, git default editor, anything using $EDITOR
# without one explicitly set, etc.
say "Setting vim as system default editor..."
update-alternatives --set editor /usr/bin/vim.basic 2>/dev/null \
  || update-alternatives --set editor /usr/bin/vim 2>/dev/null \
  || warn "couldn't auto-set editor; nano remains default"
# System-wide /etc/environment fallback so non-login shells get it too
if ! grep -q "^EDITOR=" /etc/environment; then
  echo "EDITOR=vim" >> /etc/environment
  echo "VISUAL=vim" >> /etc/environment
fi
ok "vim is the default editor"

# ---- 4. prime-run wrapper for PRIME offload ---------------------------------
# The NVIDIA driver itself is installed via the separate `nvidia-installer.sh`
# script (Dennis Hilk's installer). This step just provides the `prime-run`
# helper that lets you launch any app on the dGPU on demand.
say "Creating prime-run helper for PRIME offload..."

cat > /usr/local/bin/prime-run <<'EOF'
#!/usr/bin/env bash
# prime-run: run a command on the NVIDIA dGPU via PRIME offload
# Usage: prime-run <command> [args...]
# Example: prime-run blender
__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_NV_optimus=NVIDIA_only \
exec "$@"
EOF
chmod +x /usr/local/bin/prime-run

# Make sure modeset is enabled for Wayland (works whether or not NVIDIA
# is installed — file is read by the kernel only if the module loads)
mkdir -p /etc/modprobe.d
cat > /etc/modprobe.d/nvidia-modeset.conf <<'EOF'
options nvidia-drm modeset=1 fbdev=1
EOF

ok "prime-run helper installed"
echo "  ${YELLOW}Note${NC}: install the NVIDIA driver separately via the menu (Drivers → NVIDIA)"

# ---- 5. kernel parameters for P52 + NVIDIA ----------------------------------
say "Setting kernel parameters for P52 display compatibility..."

# Backup grub config once
[ -f /etc/default/grub.bak ] || cp /etc/default/grub /etc/default/grub.bak

# Build the desired params
# - i915.enable_psr=0: disable Panel Self-Refresh (broken on P52 internal panel)
# - nvidia-drm.modeset=1: required for Wayland
# - nvidia-drm.fbdev=1: framebuffer for nvidia
NEW_PARAMS="quiet i915.enable_psr=0 i915.enable_fbc=0 nvidia-drm.modeset=1 nvidia-drm.fbdev=1"

# Replace the GRUB_CMDLINE_LINUX_DEFAULT line
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"${NEW_PARAMS}\"|" /etc/default/grub

update-grub
ok "GRUB params updated (effective on next reboot)"

# ---- 6. PipeWire (modern audio, Wayland-friendly) --------------------------
say "Installing PipeWire (replacing PulseAudio)..."

# Debian 13 ships pipewire by default for new installs but be explicit
apt install -y \
  pipewire \
  pipewire-pulse \
  pipewire-alsa \
  pipewire-jack \
  wireplumber \
  rtkit \
  pavucontrol

# Enable per-user services (the user, not root)
sudo -u "$REAL_USER" systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || \
  warn "couldn't enable pipewire for $REAL_USER (no graphical session yet — will start on next login)"

ok "PipeWire installed"

# ---- 7. ThinkPad power management (TLP) -------------------------------------
say "Installing TLP for ThinkPad power management..."
apt install -y tlp tlp-rdw

# A reasonable default config for a P52 daily driver
cat > /etc/tlp.d/00-p52.conf <<'EOF'
# Custom TLP config for ThinkPad P52
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

CPU_MIN_PERF_ON_AC=0
CPU_MAX_PERF_ON_AC=100
CPU_MIN_PERF_ON_BAT=0
CPU_MAX_PERF_ON_BAT=60

# ThinkPad battery thresholds (preserves battery longevity)
# Battery charges to 85% then stops. Comment out if you want full charge.
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=85

RUNTIME_PM_ON_AC=auto
RUNTIME_PM_ON_BAT=auto
EOF

systemctl enable --now tlp
ok "TLP configured"

# ---- 8. Bluetooth -----------------------------------------------------------
say "Setting up Bluetooth..."
apt install -y bluetooth bluez blueman
systemctl enable --now bluetooth
ok "Bluetooth enabled"

# ---- 9. Fingerprint reader -------------------------------------------------
say "Setting up fingerprint reader..."
apt install -y fprintd libpam-fprintd
ok "fprintd installed (run 'fprintd-enroll' as your user to enroll fingerprints)"

# ---- 10. Fonts --------------------------------------------------------------
say "Installing fonts (Noto, JetBrainsMono, Inter)..."
apt install -y \
  fonts-noto \
  fonts-noto-cjk \
  fonts-noto-color-emoji \
  fonts-jetbrains-mono \
  fonts-inter \
  fonts-roboto \
  fonts-firacode
ok "fonts installed"

# ---- 11. ZSH ----------------------------------------------------------------
say "Installing zsh..."
apt install -y zsh zsh-autosuggestions zsh-syntax-highlighting

# Set zsh as the default shell for the user
if [ "$(getent passwd "$REAL_USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
  chsh -s /usr/bin/zsh "$REAL_USER"
  ok "zsh set as default shell for $REAL_USER (effective on next login)"
else
  ok "zsh already the default shell"
fi

# ---- 12. flatpak (optional but useful for GUI apps) ------------------------
say "Installing flatpak + flathub repo..."
apt install -y flatpak gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
ok "flatpak ready"

# ---- 13. SSH client config helper -------------------------------------------
# Just install the agent so existing keys work
say "Setting up ssh-agent..."
apt install -y openssh-client
ok "openssh-client present"

# ---- summary ----------------------------------------------------------------
echo
ok "=== 01-base.sh complete ==="
echo
cat <<EOF
Next steps:
  1. ${YELLOW}sudo reboot${NC}
  2. After reboot, verify NVIDIA:
     ${BLUE}nvidia-smi${NC}                                    # should show Quadro P2000
     ${BLUE}prime-run glxinfo | grep "OpenGL renderer"${NC}    # should show NVIDIA
  3. Run ${YELLOW}sudo ./02-niri-dms.sh${NC}

If NVIDIA doesn't load after reboot:
  - Check kernel headers: ${BLUE}dpkg -l linux-headers-\$(uname -r)${NC}
  - Force DKMS rebuild:   ${BLUE}sudo dkms autoinstall${NC}
  - Check loaded modules: ${BLUE}lsmod | grep nvidia${NC}
EOF
