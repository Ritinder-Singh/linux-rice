#!/usr/bin/env bash
# =============================================================================
# lib/gpu.sh — GPU detection and driver installation
# =============================================================================

install_gpu_drivers() {
    log_section "GPU Driver Setup"

    echo -e "${BOLD}Detected GPU(s):${RESET}"
    lspci | grep -iE 'vga|3d|display' || echo "  (none detected via lspci)"
    echo ""

    echo -e "Select your GPU type:"
    echo "  1) NVIDIA"
    echo "  2) AMD"
    echo "  3) Intel (integrated)"
    echo "  4) VirtualBox / No dedicated GPU (skip drivers)"
    echo ""
    read -rp "$(echo -e "${YELLOW}Enter choice [1-4]: ${RESET}")" gpu_choice

    case "$gpu_choice" in
        1) _install_nvidia ;;
        2) _install_amd ;;
        3) _install_intel ;;
        4) log_info "Skipping GPU driver installation." ;;
        *) log_warn "Invalid choice. Skipping GPU drivers." ;;
    esac
}

_install_nvidia() {
    log_section "NVIDIA Driver Installation"

    log_step "Adding graphics-drivers PPA..."
    run sudo add-apt-repository -y ppa:graphics-drivers/ppa
    run sudo apt-get update

    log_step "Installing nvidia-driver-550 (latest stable)..."
    apt_install nvidia-driver-550 nvidia-utils-550

    log_step "Installing CUDA toolkit..."
    # CUDA 12.x via network installer
    local cuda_pin="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-ubuntu2404.pin"
    local cuda_repo="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb"
    run curl -fsSL "$cuda_pin" | sudo tee /etc/apt/preferences.d/cuda-repository-pin-600 > /dev/null
    download "$cuda_repo" /tmp/cuda-keyring.deb
    run sudo dpkg -i /tmp/cuda-keyring.deb
    run sudo apt-get update
    apt_install cuda-toolkit-12-4

    log_step "Installing cuDNN (for ML workloads)..."
    apt_install libcudnn9-cuda-12 libcudnn9-dev-cuda-12

    log_step "Installing nvidia-container-toolkit (for Docker GPU support)..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null
    run sudo apt-get update
    apt_install nvidia-container-toolkit
    run sudo nvidia-ctk runtime configure --runtime=docker
    run sudo systemctl restart docker

    # Hyprland env vars for NVIDIA
    local hypr_env="$HOME/.config/hypr/env_nvidia.conf"
    mkdir -p "$HOME/.config/hypr"
    cat > "$hypr_env" <<'EOF'
# NVIDIA-specific Hyprland environment variables
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
EOF
    log_ok "Written NVIDIA Hyprland env vars to $hypr_env"
    log_warn "A reboot is required for NVIDIA drivers to take effect."
}

_install_amd() {
    log_section "AMD Driver Installation"

    log_step "Installing Mesa + AMDGPU open-source drivers..."
    run sudo add-apt-repository -y ppa:kisak/kisak-mesa
    run sudo apt-get update
    apt_install mesa-vulkan-drivers libvulkan1 vulkan-tools \
        xserver-xorg-video-amdgpu \
        radeontop \
        libdrm-amdgpu1

    log_step "Installing ROCm (AMD compute — for ML)..."
    run sudo apt-get install -y wget gnupg
    wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/rocm-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/rocm-archive-keyring.gpg] https://repo.radeon.com/rocm/apt/6.1 jammy main" | \
        sudo tee /etc/apt/sources.list.d/rocm.list > /dev/null
    run sudo apt-get update
    apt_install rocm-opencl-runtime hip-runtime-amd

    log_ok "AMD drivers installed. Wayland/Hyprland works natively with AMDGPU."
}

_install_intel() {
    log_section "Intel Integrated Graphics"

    log_step "Installing Intel media driver + Vulkan..."
    apt_install intel-media-va-driver-non-free \
        mesa-vulkan-drivers \
        libvulkan1 \
        vulkan-tools \
        i965-va-driver \
        libva-drm2 \
        libva-x11-2

    log_ok "Intel integrated graphics drivers installed."
    log_info "Hyprland works natively on Intel via Mesa/i915."
}
