# Linux Rice Setup Guide

A from-scratch NixOS rice build — development focused, tiling WM, high quality graphics, dark + light themes.

---

## Architecture Decisions

| Decision | Choice |
|---|---|
| Distro | NixOS (minimal, no GUI base) |
| Config style | Flakes + Home Manager (integrated as NixOS module) |
| Window Manager | Hyprland (Wayland, dynamic tiling) |
| Color engine | Matugen — full wallpaper-driven, dark + light auto-generated |
| Wallpaper style | Minimal / space / geometric — cool and neutral tones |

---

## Step 1 — Get the ISO

- Go to `nixos.org/download`
- Download the **Minimal ISO image** (not GNOME/KDE)
- Flash with Balena Etcher, Ventoy, or `dd`

---

## Step 2 — Boot & Partition

Boot into the live environment. You'll land at a root shell.

Check your disk name first:
```bash
lsblk
```

Replace `/dev/sda` below with your actual disk.

**UEFI systems (most modern hardware):**
```bash
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary linux-swap 512MB 8GB   # adjust swap to your RAM size
parted /dev/sda -- mkpart primary ext4 8GB 100%

mkfs.fat -F 32 -n boot /dev/sda1
mkswap -L swap /dev/sda2
mkfs.ext4 -L nixos /dev/sda3

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/sda2
```

---

## Step 3 — Generate Base Config

```bash
nixos-generate-config --root /mnt
```

This creates two files:
- `/mnt/etc/nixos/hardware-configuration.nix` — auto-detected hardware, **do not edit**
- `/mnt/etc/nixos/configuration.nix` — your system config, edit this next

---

## Step 4 — Minimal configuration.nix

Open with:
```bash
nano /mnt/etc/nixos/configuration.nix
```

Replace contents with the following (keep the `imports` line as-is):

```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "your-hostname";
  networking.networkmanager.enable = true;

  # Locale & timezone
  time.timeZone = "America/New_York";  # change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable flakes (critical)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Your user
  users.users.yourusername = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };

  # Minimal packages for bootstrapping
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];

  programs.zsh.enable = true;

  # Allow unfree packages (needed later for fonts, some tools)
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11"; # must match what nixos-generate-config set
}
```

---

## Step 5 — Install

```bash
nixos-install
# sets root password at end of install
reboot
```

After reboot, log in as root and set your user password:
```bash
passwd yourusername
```

Then log in as your user. Verify networking:
```bash
ping google.com
```

---

## Step 6 — Hardware-Specific Config (HP ZBook Firefly 16 G9)

> **Do this after first boot**, before setting up the flake.

This laptop has **hybrid graphics** — Intel Iris Xe (integrated) + NVIDIA T550 (discrete).
NixOS needs explicit config for this or you'll get a broken display setup.

### Find your GPU bus IDs

After install, run:
```bash
lspci | grep -E "VGA|3D"
```

You'll see something like:
```
00:02.0 VGA compatible controller: Intel Corporation ...
01:00.0 3D controller: NVIDIA Corporation ...
```

The numbers before the space are your bus IDs. Note them — you'll need them in the config below.

### Add to configuration.nix

```nix
# NVIDIA drivers
services.xserver.videoDrivers = [ "nvidia" ];

hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
  powerManagement.finegrained = true;   # turn off dGPU when idle
  open = false;                          # use proprietary driver (more stable)
  nvidiaSettings = true;

  prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true;           # gives you `nvidia-offload` command
    };
    # Replace with your actual bus IDs from lspci above
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };
};

# Intel iGPU support
hardware.opengl = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;
};
```

### How it works

- By default everything runs on the **Intel iGPU** (saves battery, runs cool)
- Prefix any command with `nvidia-offload` to run it on the NVIDIA GPU
- Example: `nvidia-offload blender` or `nvidia-offload glxinfo`
- Wayland compositors (like Hyprland) can be configured to use the dGPU when needed

---

## Step 7 — Set Up Flake Config Repo

The full config lives in `nixos-config/`. Push it to a private GitHub repo, then run the bootstrap script.

### Directory structure
```
nixos-config/
├── flake.nix                          # entry point, pins all inputs
├── flake.lock                         # auto-generated, commit this
├── install.sh                         # bootstrap script
├── hosts/
│   └── zbook/
│       ├── configuration.nix          # system config (NVIDIA, audio, users, fonts)
│       └── hardware-configuration.nix # auto-generated on install, do not edit
└── home/
    ├── default.nix                    # home-manager root
    └── modules/
        ├── hyprland/                  # WM, keybinds, window rules, hyprlock
        ├── waybar/                    # status bar
        ├── terminal/                  # Kitty, Zellij, Fastfetch
        ├── shell/                     # Zsh, Starship, aliases, bat, fzf
        ├── editors/                   # Neovim/LazyVim, VS Code
        ├── theme/                     # Matugen, Rofi, GTK, wallpaper scripts
        ├── apps/                      # browser, file managers, system tools
        └── dev/                       # all dev languages and tools
```

### Bootstrap (after fresh NixOS install)
```bash
# On your new NixOS machine, as your normal user:
bash <(curl -s https://raw.githubusercontent.com/mrmackaniel/nixos-rice/main/install.sh)
```

The script will:
1. Clone the config to `~/.config/nixos`
2. Copy your `hardware-configuration.nix`
3. Prompt you to set GPU bus IDs, timezone, git email
4. Run `nixos-rebuild switch`

### Manual rebuild (after any config change)
```bash
rebuild   # alias for: sudo nixos-rebuild switch --flake ~/.config/nixos#zbook
```

---

## Step 8 — Window Manager (Hyprland)

### Visual Style
| Setting | Value |
|---|---|
| Rounded corners | 6px radius (subtle) |
| Gaps | 6px (tight) |
| Blur | Strong frosted glass |
| Window borders | Thin glowing accent on focused window only |
| Animations | Smooth (Hyprland built-in) |

### Keybinds

#### Core WM
| Keybind | Action |
|---|---|
| `SUPER + Return` | Open Kitty |
| `SUPER + Q` | Close window |
| `SUPER + Space` | Open Rofi launcher |
| `SUPER + E` | Open Yazi (file manager) |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + V` | Toggle floating |
| `SUPER + P` | Toggle pseudotile |

#### Navigation
| Keybind | Action |
|---|---|
| `SUPER + H/J/K/L` | Move focus left/down/up/right |
| `SUPER + SHIFT + H/J/K/L` | Move window left/down/up/right |
| `SUPER + 1-9` | Switch to workspace 1-9 |
| `SUPER + SHIFT + 1-9` | Move window to workspace 1-9 |
| `SUPER + mouse scroll` | Cycle workspaces |

#### Apps
| Keybind | Action |
|---|---|
| `SUPER + B` | Open Zen Browser |
| `SUPER + G` | Open lazygit |
| `SUPER + M` | Open btm (system monitor) |
| `SUPER + N` | Open Zellij session |

#### System
| Keybind | Action |
|---|---|
| `SUPER + SHIFT + S` | Screenshot (region select) — Hyprshot |
| `SUPER + SHIFT + W` | Open wallpaper picker (Rofi + swww) |
| `SUPER + SHIFT + T` | Toggle dark/light theme |
| `SUPER + SHIFT + R` | Reload Hyprland config |
| `SUPER + SHIFT + E` | Exit Hyprland |

#### Zellij (inside terminal)
| Keybind | Action |
|---|---|
| `CTRL + T` | New tab |
| `CTRL + \|` | Split vertical |
| `CTRL + -` | Split horizontal |
| `ALT + H/J/K/L` | Navigate panes |

---

## Step 9 — Terminal & Shell

> **Coming next**

---

## Step 10 — Theme System (Dark + Light)

> **Coming next**

---

## Step 11 — Dev Tools & Programs

> **Coming next**

---

## TODO

- [ ] Design a custom reference wallpaper — include all tool names, config file paths, keybinds, and shortcuts. Acts as a visual cheat sheet baked into the wallpaper itself.
- [ ] Design a custom EWW widget with round dial graphics for volume control (old-school tech device aesthetic).
