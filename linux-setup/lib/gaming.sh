#!/usr/bin/env bash
# =============================================================================
# lib/gaming.sh — Gaming setup
# Covers: Steam + Proton/Wine
# =============================================================================

setup_gaming() {
    log_section "Gaming Setup (Steam + Proton/Wine)"

    # Enable 32-bit architecture (required for Steam)
    log_step "Enabling 32-bit architecture..."
    run sudo dpkg --add-architecture i386
    run sudo apt-get update

    # Wine + dependencies
    log_step "Installing Wine + 32-bit libraries..."
    apt_install \
        wine \
        wine32 \
        wine64 \
        libwine \
        libwine:i386 \
        fonts-wine \
        winetricks

    # Steam
    if ! has_cmd steam; then
        log_step "Installing Steam..."
        download "https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb" /tmp/steam.deb
        run sudo dpkg -i /tmp/steam.deb 2>/dev/null || \
            run sudo apt-get install -f -y
        run rm -f /tmp/steam.deb
    else
        log_info "Steam already installed."
    fi

    # Proton-GE (community Proton build with better game compatibility)
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

    # Vulkan support
    apt_install \
        vulkan-tools \
        mesa-vulkan-drivers \
        libvulkan1 \
        libvulkan1:i386 2>/dev/null || true

    log_ok "Steam + Proton/Wine installed."
    log_info "After launching Steam: Settings → Compatibility → Enable Steam Play for all titles → Proton-GE"
}
