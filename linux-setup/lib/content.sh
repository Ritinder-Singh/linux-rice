#!/usr/bin/env bash
# =============================================================================
# lib/content.sh — Content Creation
# Covers: OBS Studio + plugins (background removal, noise suppression,
#         virtual camera, move transition, source clone)
# =============================================================================

setup_content() {
    log_section "Content Creation (OBS Studio + Plugins)"

    _install_obs
    _install_obs_plugins
    _configure_obs
}

_install_obs() {
    if ! has_cmd obs; then
        if [[ "$DISTRO" == "arch" ]]; then
            log_step "Installing OBS Studio via pacman..."
            run sudo pacman -S --noconfirm --needed obs-studio
        else
            log_step "Adding OBS Studio PPA..."
            run sudo add-apt-repository -y ppa:obsproject/obs-studio
            run sudo apt-get update
            pkg_install obs-studio
        fi
    else
        log_info "OBS Studio already installed."
    fi

    # PipeWire virtual camera support (v4l2loopback)
    if [[ "$DISTRO" == "arch" ]]; then
        run yay -S --noconfirm --needed v4l2loopback-dkms
    else
        pkg_install v4l2loopback-dkms v4l2loopback-utils
    fi

    log_ok "OBS Studio installed."
}

_install_obs_plugins() {
    log_section "OBS Plugins"

    local OBS_PLUGIN_DIR="/usr/lib/x86_64-linux-gnu/obs-plugins"
    local OBS_DATA_DIR="/usr/share/obs/obs-plugins"
    run sudo mkdir -p "$OBS_PLUGIN_DIR" "$OBS_DATA_DIR"

    # ── obs-backgroundremoval ──────────────────────────────────────────────────
    if [[ ! -f "$OBS_PLUGIN_DIR/obs-backgroundremoval.so" ]]; then
        log_step "Installing obs-backgroundremoval..."
        if [[ "$DISTRO" == "arch" ]]; then
            run yay -S --noconfirm --needed obs-backgroundremoval 2>/dev/null || \
                log_warn "obs-backgroundremoval not in AUR — install manually."
        else
            local bgr_version
            bgr_version=$(curl -fsSL "https://api.github.com/repos/occ-ai/obs-backgroundremoval/releases/latest" | \
                jq -r '.tag_name')
            download "https://github.com/occ-ai/obs-backgroundremoval/releases/download/${bgr_version}/obs-backgroundremoval-${bgr_version}-ubuntu-24.04-x86_64.tar.gz" \
                /tmp/obs-bgr.tar.gz 2>/dev/null || \
                log_warn "obs-backgroundremoval: could not download for Ubuntu 24.04. Check releases manually."

            if [[ -f /tmp/obs-bgr.tar.gz ]]; then
                run sudo tar -xzf /tmp/obs-bgr.tar.gz -C /
                run rm -f /tmp/obs-bgr.tar.gz
                log_ok "obs-backgroundremoval installed."
            fi
        fi
    else
        log_info "obs-backgroundremoval already installed."
    fi

    # ── obs-noise-suppression ─────────────────────────────────────────────────
    log_step "Installing noise suppression support..."
    if [[ "$DISTRO" == "ubuntu" ]]; then
        pkg_install obs-plugins libspeexdsp-dev 2>/dev/null || true
    fi

    # NoiseTorch (system-wide microphone noise suppression via PipeWire)
    if ! has_cmd noisetorch; then
        if [[ "$DISTRO" == "arch" ]]; then
            run yay -S --noconfirm --needed noisetorch 2>/dev/null || \
                log_warn "noisetorch not found in AUR — install manually."
        else
            local nt_version
            nt_version=$(curl -fsSL "https://api.github.com/repos/noisetorch/NoiseTorch/releases/latest" | \
                jq -r '.tag_name')
            download "https://github.com/noisetorch/NoiseTorch/releases/download/${nt_version}/NoiseTorch_x64.tgz" \
                /tmp/noisetorch.tgz 2>/dev/null || true

            if [[ -f /tmp/noisetorch.tgz ]]; then
                run tar -xzf /tmp/noisetorch.tgz -C /tmp/
                run install -m 755 /tmp/.local/bin/noisetorch "$HOME/.local/bin/noisetorch"
                run rm -rf /tmp/noisetorch.tgz /tmp/.local
                log_ok "NoiseTorch installed."
            fi
        fi
    fi

    # ── obs-move-transition ────────────────────────────────────────────────────
    if [[ ! -f "$OBS_PLUGIN_DIR/obs-move-transition.so" ]]; then
        log_step "Installing obs-move-transition..."
        if [[ "$DISTRO" == "arch" ]]; then
            run yay -S --noconfirm --needed obs-move-transition 2>/dev/null || \
                log_warn "obs-move-transition not in AUR — install manually."
        else
            local mt_version
            mt_version=$(curl -fsSL "https://api.github.com/repos/exeldro/obs-move-transition/releases/latest" | \
                jq -r '.tag_name')
            download "https://github.com/exeldro/obs-move-transition/releases/download/${mt_version}/obs-move-transition-${mt_version}-ubuntu-24.04-x86_64.zip" \
                /tmp/obs-move.zip 2>/dev/null || true

            if [[ -f /tmp/obs-move.zip ]]; then
                run sudo unzip -o /tmp/obs-move.zip -d /
                run rm -f /tmp/obs-move.zip
                log_ok "obs-move-transition installed."
            fi
        fi
    fi

    # ── obs-source-clone ───────────────────────────────────────────────────────
    if [[ ! -f "$OBS_PLUGIN_DIR/obs-source-clone.so" ]]; then
        log_step "Installing obs-source-clone..."
        local sc_version
        sc_version=$(curl -fsSL "https://api.github.com/repos/exeldro/obs-source-clone/releases/latest" | \
            jq -r '.tag_name')
        download "https://github.com/exeldro/obs-source-clone/releases/download/${sc_version}/obs-source-clone-${sc_version}-ubuntu-24.04-x86_64.zip" \
            /tmp/obs-clone.zip 2>/dev/null || true

        if [[ -f /tmp/obs-clone.zip ]]; then
            run sudo unzip -o /tmp/obs-clone.zip -d /
            run rm -f /tmp/obs-clone.zip
            log_ok "obs-source-clone installed."
        fi
    fi

    log_ok "OBS plugins installation complete."
}

_configure_obs() {
    log_section "OBS Studio Configuration"

    # Enable virtual camera (v4l2loopback module)
    if ! lsmod | grep -q v4l2loopback; then
        log_step "Loading v4l2loopback module..."
        run sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
    fi

    # Persist v4l2loopback across reboots
    echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf > /dev/null
    echo 'options v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1' | \
        sudo tee /etc/modprobe.d/v4l2loopback.conf > /dev/null

    log_ok "OBS virtual camera configured (device: /dev/video10)."
    log_info "Start OBS → Tools → Virtual Camera → Start to enable the virtual cam."
}
