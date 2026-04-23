#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Arch Rice Bootstrap Script
# Run after a fresh minimal Arch install, logged in as your normal user.
# Usage: bash install.sh
# ─────────────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()     { echo -e "${BLUE}[rice]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
err()     { echo -e "${RED}[✗]${NC} $1"; }

FAILED_PKGS=()

# Install packages one by one so a single failure doesn't kill everything
pacman_install() {
    for pkg in "$@"; do
        sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null \
            && echo -e "  ${GREEN}✓${NC} $pkg" \
            || { err "failed: $pkg"; FAILED_PKGS+=("$pkg"); }
    done
}

paru_install() {
    for pkg in "$@"; do
        paru -S --needed --noconfirm "$pkg" 2>/dev/null \
            && echo -e "  ${GREEN}✓${NC} $pkg" \
            || { err "failed: $pkg"; FAILED_PKGS+=("$pkg"); }
    done
}

# ── Checks ────────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && { err "Do not run as root."; exit 1; }
command -v pacman &>/dev/null || { err "pacman not found. Are you on Arch?"; exit 1; }
ping -c1 archlinux.org &>/dev/null || { err "No network connection."; exit 1; }

# ── Step 1: Install paru ──────────────────────────────────────────────────────
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

# ── Step 2: Official repo packages ───────────────────────────────────────────
log "Installing pacman packages..."

pacman_install \
    `# Hyprland stack` \
    hyprland hyprlock hypridle brightnessctl \
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
    waybar rofi-wayland \
    slurp grim wl-clipboard libnotify \
    \
    `# Terminal & shell` \
    kitty zellij zsh zsh-autosuggestions zsh-syntax-highlighting starship \
    \
    `# CLI tools` \
    eza bat zoxide lazygit fzf ripgrep fd jq htop bottom \
    fastfetch figlet cava git-delta direnv shellcheck shfmt \
    \
    `# Media` \
    playerctl pipewire pipewire-alsa pipewire-pulse pipewire-jack \
    wireplumber pavucontrol mpv imv \
    \
    `# Bluetooth` \
    bluez bluez-utils blueman \
    \
    `# Fonts & theme` \
    ttf-monaspace-nerd ttf-jetbrains-mono-nerd \
    noto-fonts noto-fonts-cjk noto-fonts-emoji \
    papirus-icon-theme nwg-look qt5ct \
    \
    `# File managers` \
    yazi thunar thunar-archive-plugin thunar-volman file-roller gvfs \
    \
    `# Display manager` \
    greetd \
    \
    `# System` \
    polkit-gnome networkmanager network-manager-applet \
    tailscale pciutils xdg-utils shared-mime-info rtkit \
    \
    `# Dev base` \
    git git-lfs github-cli neovim \
    nodejs npm python python-pipx \
    go rustup clang cmake ninja llvm \
    zig ruby ocaml opam jdk21-openjdk kotlin gradle maven \
    \
    `# DevOps` \
    kubectl helm k9s podman podman-compose \
    \
    `# Apps` \
    chromium keepassxc

success "Pacman packages done"

# ── Step 3: AUR packages ──────────────────────────────────────────────────────
log "Installing AUR packages..."

paru_install \
    hyprshot \
    swww \
    swayosd \
    swaync \
    matugen \
    greetd-tuigreet \
    bibata-cursor-theme \
    adwaita-qt5-git \
    zen-browser-bin \
    vscodium-bin \
    obsidian \
    ngrok \
    chromedriver \
    opentofu \
    terragrunt \
    fnm \
    uv \
    fvm \
    android-studio \
    httpie \
    curlie \
    yq

success "AUR packages done"

# ── Step 4: Rust toolchain ────────────────────────────────────────────────────
log "Setting up Rust toolchain..."
rustup default stable
rustup component add rust-analyzer
success "Rust toolchain ready"

# ── Step 5: NVIDIA drivers ────────────────────────────────────────────────────
log "Installing NVIDIA drivers..."
paru_install nvidia nvidia-utils nvidia-prime lib32-nvidia-utils

# ── Step 6: Copy dotfiles ─────────────────────────────────────────────────────
log "Copying dotfiles..."

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for dir in "$DOTFILES_DIR"/.config/*/; do
    name=$(basename "$dir")
    mkdir -p "$HOME/.config/$name"
    cp -r "$dir"* "$HOME/.config/$name/" 2>/dev/null || true
done

cp "$DOTFILES_DIR"/.zshrc     "$HOME/.zshrc"
cp "$DOTFILES_DIR"/.zshenv    "$HOME/.zshenv"
cp "$DOTFILES_DIR"/.gitconfig "$HOME/.gitconfig"

chmod +x "$HOME/.config/hypr/scripts/wallpaper-picker.sh"
chmod +x "$HOME/.config/hypr/scripts/toggle-theme.sh"

success "Dotfiles copied"

# ── Step 7: Default shell ─────────────────────────────────────────────────────
log "Setting zsh as default shell..."
chsh -s /usr/bin/zsh
success "Default shell set to zsh"

# ── Step 8: Services ──────────────────────────────────────────────────────────
log "Enabling services..."

sudo systemctl enable --now NetworkManager   || true
sudo systemctl enable --now bluetooth        || true
sudo systemctl enable --now tailscaled       || true
sudo systemctl enable greetd                 || true

systemctl --user enable --now pipewire       || true
systemctl --user enable --now pipewire-pulse || true
systemctl --user enable --now wireplumber    || true

success "Services enabled"

# ── Step 9: greetd ────────────────────────────────────────────────────────────
log "Configuring greetd..."
sudo tee /etc/greetd/config.toml > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --cmd Hyprland"
user = "greeter"
EOF
success "greetd configured"

# ── Step 10: NVIDIA PRIME ─────────────────────────────────────────────────────
log "NVIDIA PRIME setup..."
echo ""
warn "Run: lspci | grep -E 'VGA|3D'  to get your bus IDs"
warn "Then add to /etc/modprobe.d/nvidia.conf:"
warn "  options nvidia-drm modeset=1"
warn "And to /etc/environment:"
warn "  LIBVA_DRIVER_NAME=nvidia"
warn "  GBM_BACKEND=nvidia-drm"
warn "  __GLX_VENDOR_LIBRARY_NAME=nvidia"
warn "  WLR_NO_HARDWARE_CURSORS=1"
echo ""

# ── Step 11: Wallpaper dir ────────────────────────────────────────────────────
mkdir -p "$HOME/Pictures/wallpapers"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ ${#FAILED_PKGS[@]} -gt 0 ]]; then
    echo ""
    warn "The following packages failed to install:"
    for pkg in "${FAILED_PKGS[@]}"; do
        echo -e "    ${RED}✗${NC} $pkg"
    done
    echo ""
    echo "  Retry with: paru -S ${FAILED_PKGS[*]}"
fi

echo ""
echo "  Next: reboot, then SUPER+SHIFT+W to set a wallpaper"
echo ""
