# Debian + niri + DMS on ThinkPad P52

A pragmatic, scripted setup for a Lenovo ThinkPad P52 (i7-8850H, NVIDIA Quadro
P2000 Mobile, 63 GB RAM) running Debian with niri compositor and
DankMaterialShell — with GNOME as a fallback for when DMS misbehaves.

## Why this layout

Hard-won lessons from prior attempts:

- **Fedora** had subtle bugs that made daily use painful
- **NixOS** is excellent for stable, reproducible setups, but the niri+DMS
  packaging on NixOS is currently fragile. A week of debugging
  produced a half-working system.
- **Pure Arch + DMS** works (DMS upstream tests against Arch) but Arch's
  rolling nature is at odds with "stable daily driver."

The conclusion: **stable Debian base + experimental shell layered on top, with a
GNOME fallback session for when the experimental layer breaks.**

If DMS breaks, log out → pick GNOME at the greeter → keep working. Debug DMS
on your own time. Your laptop never stops being usable.

## What this gives you

- **Base**: Debian 13 (Trixie) — stable, tested, predictable
- **Compositor**: niri (scrollable tiling, Wayland)
- **Shell**: DankMaterialShell — bar, launcher, notifications, dynamic theming
- **Fallback**: GNOME — for when DMS or niri break
- **GPU**: NVIDIA proprietary driver via Debian's `nvidia-driver` (PRIME offload
  for battery, dGPU on demand)
- **Disk**: BTRFS with subvolumes (or ext4 if you prefer simpler)
- **Audio**: PipeWire
- **ThinkPad**: TLP power management, fwupd firmware updates, fingerprint reader

## Installation order

After Debian installer finishes and `sudo` works, clone this repo and run
the main menu:

```bash
sudo apt install git
git clone <your-bitbucket-url> ~/p52-setup
cd ~/p52-setup
chmod +x install.sh scripts/*.sh
sudo ./install.sh
```

Walk through the menu in this order:

1. **Drivers → Base system** (apt sources, fonts, audio, TLP, prime-run helper)
2. **Drivers → NVIDIA** (pick option 1 — Debian stable repo)
3. **Reboot**, then verify with `nvidia-smi`
4. **Apps → CLI essentials** (zsh, zoxide, fzf, ripgrep, fastfetch...)
5. **Apps → Dev environment** (flatpak, Python+pipx, nvs+node22, docker, gh)
6. **Apps → GUI** (VSCode, Thorium, Parsec)
7. **Dotfiles** (zsh/kitty/yazi/git config — run AS USER, not sudo)
8. **Compositor (DMS)** (niri + DankMaterialShell)
9. **Snapshots** (Timeshift, recommended)

After step 8, log out of GNOME and pick **niri** at the GDM session selector.

## Detailed prerequisites — before the menu

Do these once before you run `install.sh`:

1. [Pre-install BIOS settings](#1-pre-install-bios-settings)
2. [Boot the Debian installer in UEFI mode](#2-boot-the-debian-installer)
3. [Manual partitioning with optional LUKS, no slow erase](#3-partitioning-with-luks-fast-method)
4. [Install Debian with GNOME desktop](#4-debian-installer-walkthrough)
5. [First boot — get sudo working](#5-first-boot--fix-sudo-if-needed)

## 1. Pre-install BIOS settings

Hit F1 at the Lenovo splash. Set:

- **Config → Display → Graphics Device** → `Hybrid Graphics`
- **Config → Display → OS Detection for NVIDIA Optimus** → `Enabled`
- **Startup → Boot → UEFI/Legacy Boot** → `UEFI Only`
- **Security → Secure Boot** → `Disabled` (NVIDIA driver kernel modules
  aren't signed in standard Debian; re-enable later if you want with extra setup)

Save and exit.

## 2. Boot the Debian installer

1. Download the Debian 13 installer (any of these work; pick what's available):
   - **netinst** (small, downloads as it installs): https://www.debian.org/download
   - **DVD/full ISO** (larger, works offline): https://www.debian.org/CD/
2. Flash to USB or drop on Ventoy
3. Boot, pick **"Graphical install"** (NOT Legacy/BIOS variants)

## 3. Partitioning with LUKS (fast method)

Previous attempts hit two specific problems:
- The "Use entire disk and set up encrypted LVM" option **wipes the entire
  disk with random data first** — takes 30+ minutes on an NVMe
- Resulting LUKS prompt at boot can be very slow due to argon2id with high
  iterations on older CPUs

Both are solved by **manual partitioning with explicit choices**.

If you want **no encryption at all** (simpler, fine for a home laptop), skip the
LUKS bit and just create ESP + root.

### Layout

```
/dev/nvme0n1
├── nvme0n1p1  1 GiB   EFI System Partition (vfat)        → /boot/efi
└── nvme0n1p2  rest    LUKS container                     → cryptroot
    └── cryptroot      ext4 or BTRFS                      → /
```

### Steps in the installer

1. **Partitioning method** → `Manual`
2. Select your disk → "Yes, create new empty partition table" if needed
3. **Create the ESP**:
   - On free space → "Create new partition"
   - Size: `1 GB`
   - Type: `Beginning`
   - Use as: `EFI System Partition`
   - Done
4. **Create the LUKS container partition**:
   - On free space → "Create new partition"
   - Size: rest of disk
   - Use as: `physical volume for encryption`
   - **Erase data on this partition: `no`** ← this saves you 30+ minutes
   - Done
5. **Configure encrypted volumes**:
   - "Create encrypted volumes" → select the partition you marked
   - Set passphrase
   - Wait — this completes in seconds since you said no to erase
6. After it returns, you'll see a new "Encrypted volume (cryptroot)" entry
7. Select it → Use as: `Ext4 journaling file system` (or `btrfs` if you prefer)
   - Mount point: `/`
   - Done
8. **Finish partitioning and write changes to disk** → Yes

## 4. Debian installer walkthrough

Continue through the installer:

- **Hostname**: `p52` (or whatever you want; lowercase, no spaces)
- **Domain**: leave blank
- **Root password**: **leave empty** ← this auto-adds your user to sudo
- **Full name / username / password**: your choice
- **Software selection (tasksel)**:
  - ✅ Debian desktop environment
  - ✅ GNOME (uncheck others)
  - ✅ standard system utilities
  - ✅ SSH server (optional but useful)

Wait for install. Reboot when prompted. Pull the USB during BIOS post.

## 5. First boot — fix sudo if needed

Boot into Debian. Log in as your user.

Test sudo:
```bash
sudo whoami
```

If it says **"user is not in sudoers file"**, you set a root password during
install (which makes Debian skip auto-adding you to sudo). Fix:

```bash
su -
# enter the root password you set
usermod -aG sudo $(logname)
exit
# log out and back in for group change to take effect
```

If you didn't set a root password and sudo still fails, boot into recovery mode
(GRUB → Advanced → recovery) and run the same `usermod` command.

## 6. Run `01-base.sh`

Open a terminal. Get this repo onto the machine:

```bash
sudo apt install git
git clone <your-bitbucket-url> ~/p52-setup
cd ~/p52-setup
chmod +x *.sh
sudo ./01-base.sh
```

What it does:
- Updates apt
- Installs base utilities (curl, htop, build-essential, etc.)
- Adds non-free firmware repo if not already there
- Installs `nvidia-driver` (Pascal-compatible, correct for Quadro P2000)
- Configures NVIDIA PRIME offload (iGPU default, dGPU on demand)
- Installs TLP for ThinkPad battery management
- Installs fwupd for firmware updates
- Installs ZSH and sets it as the default shell
- Installs PipeWire (replaces PulseAudio for better Wayland support)

## 7. Reboot

```bash
sudo reboot
```

After reboot, verify NVIDIA:

```bash
nvidia-smi                 # should show your Quadro P2000
prime-run glxinfo | grep "OpenGL renderer"
# should print the NVIDIA card name when prefixed with prime-run
```

## 8. Run `02-niri-dms.sh`

```bash
cd ~/p52-setup
sudo ./02-niri-dms.sh
```

What it does:
- Adds the Avenge Media APT repo (DMS official)
- Installs niri, DMS, dependencies (matugen, dgop, cliphist, etc.)
- Configures DMS as a systemd user service (auto-starts when you log in)
- Installs kitty terminal, fuzzel launcher, swaync, etc.

## 9. Log into niri

1. Log out of GNOME
2. At the GDM login screen, click your username
3. Click the **gear icon** at the bottom-right → pick **niri**
4. Enter your password → niri starts → DMS bar appears

If something's broken: log out, pick **GNOME** instead, you have a working
laptop. Debug DMS later from a kitty window inside GNOME.

### DMS keybinds (defaults)

- **Super + Return** — terminal (kitty)
- **Super + Space** — app launcher (DMS spotlight)
- **Super + Q** — close window
- **Super + L** — lock screen
- **Super + Shift + E** — quit niri (logs out)

Full list: `dms ipc call help` from a terminal.

## 10. (Optional) dotfiles

If you have a dotfiles repo or want the curated zsh/git/kitty/yazi configs:

```bash
sudo ./03-dotfiles.sh
```

Or apply your own with stow, chezmoi, or whatever you prefer.

## Daily operations

### Update the system

```bash
sudo apt update && sudo apt full-upgrade
```

Or use the helper:

```bash
~/p52-setup/update.sh
```

### Install a package

```bash
sudo apt install <package>
```

To track installs in your config: edit `MANUAL_INSTALLS.md` (a text file in
this repo) and commit. Not as fancy as Nix's declarative model but at least
you have a paper trail. (See "Why no `nix-add` equivalent" below.)

### Roll back if something breaks

`apt` doesn't have atomic rollback like NixOS. Options:

1. `sudo apt install <package>=<previous-version>` — pin to an older version
2. Restore from a Timeshift snapshot if you set those up (recommended — see
   `04-timeshift.sh` if you want this)
3. Boot the previous kernel from GRUB and pin it: `sudo apt-mark hold linux-image-...`

### Why no `nix-add` equivalent

NixOS could automate "edit config → rebuild → commit" because the config
*was* the source of truth. On Debian, `apt install` modifies the system
directly — there's nothing to commit. You can keep `MANUAL_INSTALLS.md` as
documentation of what you've installed, but it's not enforceable.

If you want declarative-ish package management on Debian, look at:
- **Ansible playbook** — same idea as a Nix config, but for apt-based systems
- **NixOS for apps** — yes, you can install Nix on Debian and use it just for
  user packages. Best of both worlds if you don't mind two package managers.

## Troubleshooting

### LUKS prompt is very slow at boot

```bash
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep PBKDF
```

If it shows `argon2id` with high `Memory` (>1 GiB) or `Iterations`, switch
to PBKDF2 which is fast on older CPUs:

```bash
sudo cryptsetup luksConvertKey --pbkdf pbkdf2 /dev/nvme0n1p2
```

You'll be asked for the passphrase. PBKDF2 is still secure for "stolen
laptop" threat models.

### Black screen after GRUB

Same issue we hit on NixOS. Fix with kernel parameters:

```bash
sudo nano /etc/default/grub
# Find: GRUB_CMDLINE_LINUX_DEFAULT="quiet"
# Change to:
GRUB_CMDLINE_LINUX_DEFAULT="quiet i915.enable_psr=0 nvidia-drm.modeset=1"

sudo update-grub
sudo reboot
```

### DMS shell doesn't start in niri

Check it's running:
```bash
systemctl --user status dms
```

If failed:
```bash
journalctl --user -u dms -b
```

Common causes:
- Missing config dir: `mkdir -p ~/.config/DankMaterialShell ~/.config/quickshell`
- WAYLAND_DISPLAY not set: only happens if you ran `dms` from a TTY, not from inside niri

### NVIDIA after kernel update

If a kernel update breaks NVIDIA (modules don't compile against the new
kernel headers):

```bash
sudo apt install linux-headers-$(uname -r)
sudo dkms autoinstall
sudo reboot
```

DKMS is supposed to handle this automatically but occasionally needs a
nudge.

### Sound only plays through one device / doesn't switch

PipeWire usually handles this but if not:

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

Then check the audio settings (Super+Space → "Sound" in DMS, or
`pavucontrol` from terminal).

## Repo layout

```
debian-p52/
├── README.md                   # this file
├── install.sh                  # main interactive menu — run this
├── scripts/
│   ├── 01-base.sh              # apt sources, fonts, audio, TLP, fwupd, prime-run
│   ├── nvidia-installer.sh     # standalone NVIDIA installer (Dennis Hilk's, vendored)
│   ├── apps-cli.sh             # zsh, zoxide, vim, fastfetch, fzf, ripgrep, etc.
│   ├── apps-dev.sh             # flatpak, build tools, Python+pipx, nvs+node22, gh, docker
│   ├── apps-gui.sh             # VSCode, Thorium, Parsec
│   ├── 02-niri-dms.sh          # niri compositor + DankMaterialShell
│   ├── 03-dotfiles.sh          # zsh/kitty/yazi/git/nano config (run as user)
│   ├── 04-timeshift.sh         # rollback snapshots
│   └── update.sh               # apt + flatpak + firmware update wrapper
├── MANUAL_INSTALLS.md          # log of packages installed manually
└── archive/                    # NixOS attempt — preserved as reference
    ├── nixos-attempt.md        # what worked, what didn't, lessons
    └── nix-files/              # all .nix files from the abandoned config
```

## Usage

The whole thing is driven through one entry point:

```bash
sudo ./install.sh
```

That gives you the main menu. Or jump directly to a category:

```bash
./install.sh --drivers      # base setup + NVIDIA installer
./install.sh --apps         # apps submenu (CLI / dev / GUI)
./install.sh --apps-cli     # CLI essentials only
./install.sh --apps-dev     # dev environment only
./install.sh --apps-gui     # GUI apps only
./install.sh --dms          # niri + DMS
./install.sh --dotfiles     # zsh/kitty/git config
./install.sh --update       # daily update
./install.sh --snapshots    # Timeshift setup
```

The main script handles sudo/no-sudo correctly per sub-script — you don't
need to think about which to run with sudo. The main menu uses `# RUN_AS:`
comments inside each script to know.

## Lessons archived from the NixOS attempt

See `archive/nixos-attempt.md` for the full account. Quick summary:

- **NixOS itself is solid.** The disko + flake setup got the OS booting.
- **niri-flake works** — it ships niri-stable and niri-unstable correctly.
- **DMS-on-NixOS is fragile.** The Quickshell + DMS-from-source flake
  produced a binary that can't find its own QML files. Multiple
  rebuilds, garbage collections, and version pins didn't resolve it.
- **`bin/nix-add` declarative path was a footgun.** `home.file` source
  references break the build if the file isn't tracked by git. Easy fix
  but caused install failures multiple times.
- **NVIDIA Optimus + Wayland** needs `i915.enable_psr=0` plus several
  other kernel params. The same fix applies to Debian.
- **The graphical NixOS installer would have skipped most early problems**
  but landed at the same wall (DMS packaging) eventually.
