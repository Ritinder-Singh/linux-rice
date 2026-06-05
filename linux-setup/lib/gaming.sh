#!/usr/bin/env bash
# =============================================================================
# lib/gaming.sh — Gaming setup
# Covers: Steam + Proton/Wine
# =============================================================================

setup_gaming() {
    log_section "Gaming Setup (Steam + Proton/Wine)"

    if [[ "$DISTRO" == "arch" ]]; then
        # Enable multilib repo (needed for Steam and 32-bit Wine)
        if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
            log_step "Enabling multilib repository..."
            sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
            run sudo pacman -Sy
        else
            log_info "multilib already enabled."
        fi

        log_step "Installing Steam + Wine + Winetricks via pacman..."
        run sudo pacman -S --noconfirm --needed steam wine winetricks

        # Vulkan support (Arch)
        run sudo pacman -S --noconfirm --needed \
            vulkan-tools vulkan-icd-loader lib32-vulkan-icd-loader \
            mesa lib32-mesa 2>/dev/null || true
    else
        # Ubuntu: enable 32-bit and install via apt
        log_step "Enabling 32-bit architecture..."
        run sudo dpkg --add-architecture i386
        run sudo apt-get update

        log_step "Installing Wine + 32-bit libraries..."
        pkg_install \
            wine \
            wine32 \
            wine64 \
            libwine \
            libwine:i386 \
            fonts-wine \
            winetricks

        if ! has_cmd steam; then
            log_step "Installing Steam..."
            download "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" /tmp/steam.deb
            run sudo dpkg -i /tmp/steam.deb 2>/dev/null || \
                run sudo apt-get install -f -y
            run rm -f /tmp/steam.deb
        else
            log_info "Steam already installed."
        fi

        pkg_install \
            vulkan-tools \
            mesa-vulkan-drivers \
            libvulkan1 \
            libvulkan1:i386 2>/dev/null || true
    fi

    # Proton-GE — same method on both distros
    log_step "Installing Proton-GE (community build)..."
    local PROTON_DIR="$HOME/.local/share/Steam/compatibilitytools.d"
    mkdir -p "$PROTON_DIR"

    local proton_version
    proton_version=$(curl -fsSL "https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest" | \
        jq -r '.tag_name')

    if [[ -n "$proton_version" && "$proton_version" != "null" ]]; then
        download "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${proton_version}/${proton_version}.tar.gz" \
            /tmp/proton-ge.tar.gz
        run tar -xzf /tmp/proton-ge.tar.gz -C "$PROTON_DIR/"
        run rm -f /tmp/proton-ge.tar.gz
        log_ok "Proton-GE ${proton_version} installed."
    else
        log_warn "Could not fetch Proton-GE version — install manually from https://github.com/GloriousEggroll/proton-ge-custom"
    fi

    log_ok "Steam + Proton/Wine installed."
    log_info "After launching Steam: Settings → Compatibility → Enable Steam Play for all titles → Proton-GE"
}
