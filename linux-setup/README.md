# Linux Setup Script

Personal setup script for **Ubuntu 24.04 LTS** and **Arch Linux / EndeavourOS**.

The script auto-detects which distro is running and uses the right package manager. On Arch/EndeavourOS, `yay` (AUR helper) is installed automatically before any other packages.

## What Gets Installed

| Section | Contents |
|---|---|
| **system** | Hostname, Zsh + Oh My Zsh + Starship, SSH key, UFW, Fail2ban, Tailscale, Nerd Fonts |
| **gpu** | Interactive: NVIDIA (drivers + CUDA + cuDNN), AMD (Mesa + ROCm), Intel, or skip |
| **desktop** | Hyprland, Waybar, Rofi, swww, Matugen, Hyprshot, Ghostty, Zellij, Yazi, PipeWire, greetd |
| **dev** | nvm/Node LTS + pnpm, pyenv/Python 3.12 + uv, Go, Rust, Flutter + Android SDK, Docker, kubectl + Helm + k9s, Terraform, Ansible, GitHub CLI, lazygit, lazydocker, act, Floci |
| **editors** | Neovim + LazyVim, Zed (full IDE config, Vim mode, Catppuccin), JetBrains Toolbox → Android Studio |
| **security** | Nmap, Wireshark, Metasploit, Burp Suite, John, Hashcat, Volatility 3, Autopsy, Sleuth Kit, Aircrack-ng, Gobuster, ffuf, Nikto, sqlmap, Ghidra, Binwalk, Exiftool, SecLists + Kali Linux VM (QEMU/KVM) |
| **gaming** | Steam + Proton-GE + Wine + Vulkan |
| **content** | OBS Studio + plugins (background removal, noise suppression, move transition, virtual camera), NoiseTorch |

---

## Usage

```bash
# Clone or copy to your machine
git clone https://github.com/yourusername/linux-setup.git
cd linux-setup
chmod +x install.sh

# Dry run first (recommended) — prints everything without doing anything
./install.sh --dry-run

# Full install
./install.sh

# Run only one section
./install.sh --only dev
./install.sh --only desktop
./install.sh --only security

# Skip sections
./install.sh --skip gaming,security
./install.sh --skip gpu

# Combine flags
./install.sh --dry-run --only editors
```

---

## Supported Distros

| Distro | Status | Notes |
|---|---|---|
| Ubuntu 24.04 LTS | ✅ Full support | Primary target |
| EndeavourOS (Arch-based) | ✅ Full support | Uses yay (auto-installed) |
| Arch Linux | ✅ Full support | Uses yay (auto-installed) |
| Manjaro | ⚠️ Should work | Detected as Arch, untested |

**Arch/EndeavourOS notes:**
- `yay` is installed automatically at the start of the `system` section
- Hyprland installs natively via `yay -S hyprland` — no source build required
- BlackArch repo is added automatically before the `security` section
- The `[multilib]` repo is enabled automatically before the `gaming` section

---

## VirtualBox Testing Guide (Windows Host)

### Ubuntu — Step 1: VirtualBox Setup

1. Download [Ubuntu Server 24.04 LTS x86_64 ISO](https://ubuntu.com/download/server)
2. In VirtualBox, create a new VM:
   - **Type**: Linux / Ubuntu 24.04 LTS (64-bit)
   - **RAM**: 8192 MB minimum (12288 recommended)
   - **CPU**: 4 cores
   - **Disk**: 80 GB (dynamically allocated)
3. Before starting, open VM **Settings**:
   - **System → Motherboard**: Enable EFI ✓
   - **System → Processor**: Enable PAE/NX ✓, VT-x/AMD-V ✓
   - **Display → Screen**: Video Memory 128MB, Graphics Controller **VMSVGA**, 3D Acceleration ✓
   - **Network**: NAT (default) is fine

### Ubuntu — Step 2: Install Ubuntu Server

1. Start the VM, boot from ISO
2. Follow Ubuntu Server installer — minimal install, no extras
3. Create your user account
4. Reboot into the server

### Ubuntu — Step 3: Run the Script

```bash
# On the fresh Ubuntu Server install:
sudo apt-get install -y git curl
git clone https://github.com/yourusername/linux-setup.git
cd linux-setup
chmod +x install.sh

# Dry run first
./install.sh --dry-run

# Full install (takes 30-60 min depending on internet speed)
./install.sh
```

### EndeavourOS (Arch) — VirtualBox Setup

1. Download [EndeavourOS ISO](https://endeavouros.com/) or [Arch Linux ISO](https://archlinux.org/download/)
2. In VirtualBox, create a new VM:
   - **Type**: Linux / Arch Linux (64-bit)
   - **RAM**: 8192 MB minimum
   - **CPU**: 4 cores
   - **Disk**: 80 GB (dynamically allocated)
3. VM **Settings**:
   - **Display → Screen**: Video Memory 128MB, Graphics Controller **VMSVGA**, 3D Acceleration ✓
   - **System → Processor**: Enable VT-x/AMD-V ✓
4. Install EndeavourOS with the graphical installer (Online install → select a DE to get a working display), then remove the DE after if you only want Hyprland. Or use the **No Desktop** option and run this script.
5. After install, run:

```bash
sudo pacman -S git curl
git clone https://github.com/yourusername/linux-setup.git
cd linux-setup
chmod +x install.sh
./install.sh --dry-run
./install.sh
```

### Step 4 — Testing Notes for VirtualBox

| Feature | Status in VirtualBox |
|---|---|
| apt installs | ✅ Full support |
| Zsh/shell setup | ✅ Full support |
| Dev tools (Node, Python, Go, etc.) | ✅ Full support |
| Docker | ✅ Works (not nested — Docker runs on the VM directly) |
| Hyprland/Wayland GUI | ⚠️ Works but may be slow — needs VMSVGA + 3D accel |
| KVM/Kali nested VM | ⚠️ Needs nested virtualisation enabled in VBoxManage (see below) |
| NVIDIA GPU drivers | ❌ Skip in VirtualBox — choose option 4 (VirtualBox/No GPU) |
| Steam/Gaming | ⚠️ Installs fine, games won't run without GPU |

**Enable nested virtualisation for Kali VM** (run on Windows host, VM must be powered off):
```cmd
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "YOUR-VM-NAME" --nested-hw-virt on
```

---

## File Structure

```
linux-setup/
├── install.sh          # Main entry point
├── lib/
│   ├── utils.sh        # Logging, dry-run, helpers
│   ├── system.sh       # Base system, Zsh, SSH, UFW, Fail2ban, Tailscale, Fonts
│   ├── gpu.sh          # GPU detection + drivers (NVIDIA/AMD/Intel)
│   ├── desktop.sh      # Hyprland + full WM stack + dotconfigs
│   ├── dev.sh          # Dev + DevOps tools
│   ├── editors.sh      # Neovim, Zed, Android Studio
│   ├── security.sh     # Security/forensics + Kali VM
│   ├── gaming.sh       # Steam + Proton
│   └── content.sh      # OBS + plugins
└── README.md
```

---

## Key Keybinds (Hyprland)

| Keybind | Action |
|---|---|
| `Super + Enter` | Open Ghostty terminal |
| `Super + Space` | Rofi app launcher |
| `Super + E` | Yazi file manager |
| `Super + C` | Close active window |
| `Super + F` | Fullscreen |
| `Super + T` | Toggle floating |
| `Super + H/J/K/L` | Move focus (vim-style) |
| `Super + 1-0` | Switch workspace |
| `Super + Shift + 1-0` | Move window to workspace |
| `Print` | Screenshot (full output) |
| `Super + Print` | Screenshot (region select) |
| `Super + Escape` | Lock screen (hyprlock) |
| `Super + Shift + E` | Exit Hyprland |
| `Super + V` | Clipboard history (cliphist) |

---

## Zed IDE Keybinds (Vim mode)

| Keybind | Action |
|---|---|
| `Space f f` | Find file |
| `Space f r` | Recent projects |
| `Space / ` | Search in project |
| `Space t t` | Toggle terminal |
| `Space l a` | Code actions |
| `Space l r` | Rename symbol |
| `Space l d` | Go to definition |
| `Space l f` | Format file |
| `g d` | Go to definition |
| `g r` | Find all references |
| `K` | Hover documentation |

---

## Re-running Safely

The script is **idempotent** — most steps check if something is already installed before running. Safe to re-run after failures or partial installs.

```bash
# Resume from a specific section after a failure
./install.sh --only security
./install.sh --only editors
```
