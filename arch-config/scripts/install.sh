#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Arch Rice Bootstrap Script
# Run after a fresh minimal Arch install, logged in as your normal user.
# Usage: bash install.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()     { echo -e "${BLUE}[rice]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ── Checks ────────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && error "Do not run as root."
command -v pacman &>/dev/null || error "pacman not found. Are you on Arch?"
ping -c1 archlinux.org &>/dev/null || error "No network connection."

# ── Step 1: Install paru (AUR helper) ─────────────────────────────────────────
if ! command -v paru &>/dev/null; then
    log "Installing paru..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
    rm -rf /tmp/paru
    success "paru installed"
else
    success "paru already installed"
fi

# ── Step 2: System packages ───────────────────────────────────────────────────
log "Installing system packages..."

PACMAN_PKGS=(
    # ── Hyprland stack ────────────────────────────────────────────────────────
    hyprland
    hyprlock
    hypridle
    brightnessctl
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    waybar
    rofi
    swww
    swayosd
    swaync
    hyprshot
    slurp
    grim
    wl-clipboard
    libnotify

    # ── Terminal & shell ──────────────────────────────────────────────────────
    kitty
    zellij
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
    starship

    # ── CLI tools ─────────────────────────────────────────────────────────────
    eza
    bat
    zoxide
    lazygit
    fzf
    ripgrep
    fd
    jq
    yq
    htop
    bottom
    fastfetch
    figlet
    cava
    delta
    direnv
    shellcheck
    shfmt

    # ── Media ─────────────────────────────────────────────────────────────────
    playerctl
    pipewire
    pipewire-alsa
    pipewire-pulse
    pipewire-jack
    wireplumber
    pavucontrol
    mpv
    imv

    # ── Bluetooth ─────────────────────────────────────────────────────────────
    bluez
    bluez-utils
    blueman

    # ── Theme & fonts ─────────────────────────────────────────────────────────
    ttf-monaspace-nerd
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    papirus-icon-theme
    bibata-cursor-theme
    nwg-look
    qt5ct
    adwaita-qt5

    # ── File managers ─────────────────────────────────────────────────────────
    yazi
    thunar
    thunar-archive-plugin
    thunar-volman
    file-roller
    gvfs

    # ── Display manager ───────────────────────────────────────────────────────
    greetd
    greetd-tuigreet

    # ── System ────────────────────────────────────────────────────────────────
    polkit-gnome
    networkmanager
    network-manager-applet
    tailscale
    pciutils
    xdg-utils
    shared-mime-info
    rtkit

    # ── Dev base ──────────────────────────────────────────────────────────────
    git
    git-lfs
    github-cli
    neovim
    nodejs
    npm
    python
    python-pipx
    go
    rustup
    clang
    cmake
    ninja
    llvm
    zig
    ruby
    ocaml
    opam
    jdk21-openjdk
    kotlin
    gradle
    maven

    # ── DevOps ────────────────────────────────────────────────────────────────
    kubectl
    helm
    k9s
    podman
    podman-compose

    # ── Browser testing ───────────────────────────────────────────────────────
    chromium

    # ── Apps ──────────────────────────────────────────────────────────────────
    keepassxc
    obsidian
    ngrok
)

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
success "Pacman packages installed"

# ── Step 3: AUR packages ──────────────────────────────────────────────────────
log "Installing AUR packages..."

AUR_PKGS=(
    matugen
    swayosd
    zen-browser-bin
    chromedriver
    opentofu
    terragrunt
    fnm
    uv
    fvm
    android-studio
    vscodium-bin
    httpie
    curlie
    hyprshot
    bibata-cursor-theme
    swaync
)

paru -S --needed --noconfirm "${AUR_PKGS[@]}"
success "AUR packages installed"

# ── Step 4: Rust toolchain ────────────────────────────────────────────────────
log "Setting up Rust toolchain..."
rustup default stable
rustup component add rust-analyzer
success "Rust toolchain ready"

# ── Step 5: NVIDIA drivers ────────────────────────────────────────────────────
log "Installing NVIDIA drivers..."
warn "This installs the proprietary NVIDIA driver for hybrid graphics (HP ZBook)."
warn "After install, you need to set your GPU bus IDs in /etc/modprobe.d/."

paru -S --needed --noconfirm nvidia nvidia-utils nvidia-prime lib32-nvidia-utils
success "NVIDIA drivers installed"

# ── Step 6: Copy dotfiles ─────────────────────────────────────────────────────
log "Copying dotfiles..."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# .config entries
for dir in "$DOTFILES_DIR"/.config/*/; do
    name=$(basename "$dir")
    mkdir -p "$HOME/.config/$name"
    cp -r "$dir"* "$HOME/.config/$name/" 2>/dev/null || true
done

# Shell files
cp "$DOTFILES_DIR"/.zshrc    "$HOME/.zshrc"
cp "$DOTFILES_DIR"/.zshenv   "$HOME/.zshenv"
cp "$DOTFILES_DIR"/.gitconfig "$HOME/.gitconfig"

# Make scripts executable
chmod +x "$HOME/.config/hypr/scripts/wallpaper-picker.sh"
chmod +x "$HOME/.config/hypr/scripts/toggle-theme.sh"
chmod +x "$HOME/.local/bin/"*.sh 2>/dev/null || true

success "Dotfiles copied"

# ── Step 7: Set zsh as default shell ──────────────────────────────────────────
log "Setting zsh as default shell..."
chsh -s /usr/bin/zsh
success "Default shell set to zsh"

# ── Step 8: Enable services ───────────────────────────────────────────────────
log "Enabling services..."

sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
sudo systemctl enable --now tailscaled
sudo systemctl enable greetd

# PipeWire runs as user service
systemctl --user enable --now pipewire
systemctl --user enable --now pipewire-pulse
systemctl --user enable --now wireplumber

success "Services enabled"

# ── Step 9: Configure greetd ──────────────────────────────────────────────────
log "Configuring greetd..."
sudo tee /etc/greetd/config.toml > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --cmd Hyprland"
user = "greeter"
EOF
success "greetd configured"

# ── Step 10: NVIDIA PRIME setup ───────────────────────────────────────────────
log "NVIDIA PRIME setup..."
echo ""
echo "  Run the following to get your GPU bus IDs:"
echo "  lspci | grep -E 'VGA|3D'"
echo ""
warn "Then add to /etc/modprobe.d/nvidia.conf:"
warn "  options nvidia-drm modeset=1"
warn ""
warn "And add to /etc/environment:"
warn "  LIBVA_DRIVER_NAME=nvidia"
warn "  GBM_BACKEND=nvidia-drm"
warn "  __GLX_VENDOR_LIBRARY_NAME=nvidia"
warn "  WLR_NO_HARDWARE_CURSORS=1"
echo ""
read -rp "Press Enter to continue..."

# ── Step 11: Wallpaper directory ──────────────────────────────────────────────
log "Creating wallpaper directory..."
mkdir -p "$HOME/Pictures/wallpapers"
success "Add wallpapers to ~/Pictures/wallpapers"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Next steps:"
echo "  1. Reboot"
echo "  2. Log in via greetd — Hyprland starts automatically"
echo "  3. SUPER + SHIFT + W to pick a wallpaper"
echo "  4. Set a wallpaper to generate Matugen colors"
echo ""
echo "  Key binds:"
echo "  SUPER + Return        → kitty"
echo "  SUPER + Space         → rofi launcher"
echo "  SUPER + SHIFT + L     → lock screen"
echo "  SUPER + SHIFT + E     → exit Hyprland"
echo ""
