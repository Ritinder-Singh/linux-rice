#!/usr/bin/env bash
# =============================================================================
# lib/system.sh — Base system setup
# Covers: hostname, updates, build tools, Zsh+OMZ, SSH, UFW, Fail2ban, Tailscale
# =============================================================================

setup_system() {
    [[ "$DISTRO" == "arch" ]] && _install_yay
    _set_hostname
    _system_update
    _install_base_packages
    _setup_zsh
    _setup_ssh
    _setup_ufw
    _setup_fail2ban
    _setup_tailscale
    _setup_fonts
}

# ── yay (AUR helper) — Arch only ──────────────────────────────────────────────
_install_yay() {
    if has_cmd yay; then
        log_info "yay already installed."
        return
    fi
    log_section "Installing yay (AUR helper)"
    pkg_install git base-devel
    local build_dir
    build_dir=$(mktemp -d)
    run git clone --depth=1 https://aur.archlinux.org/yay.git "$build_dir/yay"
    (cd "$build_dir/yay" && run makepkg -si --noconfirm)
    run rm -rf "$build_dir"
    log_ok "yay installed."
}

# ── Hostname ──────────────────────────────────────────────────────────────────
_set_hostname() {
    log_section "Setting Hostname"
    read -rp "$(echo -e "${YELLOW}Enter desired hostname: ${RESET}")" new_hostname
    if [[ -n "$new_hostname" ]]; then
        run sudo hostnamectl set-hostname "$new_hostname"
        # Update /etc/hosts
        if ! grep -q "$new_hostname" /etc/hosts; then
            echo "127.0.1.1   $new_hostname" | sudo tee -a /etc/hosts > /dev/null
        fi
        log_ok "Hostname set to: $new_hostname"
    else
        log_warn "No hostname entered, skipping."
    fi
}

# ── System Update ─────────────────────────────────────────────────────────────
_system_update() {
    log_section "System Update"
    if [[ "$DISTRO" == "arch" ]]; then
        log_step "Syncing and upgrading packages (pacman -Syu)..."
        run sudo pacman -Syu --noconfirm
    else
        log_step "Updating package lists..."
        run sudo apt-get update
        log_step "Upgrading installed packages..."
        run sudo apt-get upgrade -y
        log_step "Installing dist-upgrade packages..."
        run sudo apt-get dist-upgrade -y
        run sudo apt-get autoremove -y
    fi
    log_ok "System up to date."
}

# ── Base Packages ─────────────────────────────────────────────────────────────
_install_base_packages() {
    log_section "Base Packages & Build Essentials"

    # fontconfig needed for fc-cache on both distros
    pkg_install fontconfig

    pkg_install \
        build-essential \
        gcc \
        clang \
        cmake \
        make \
        pkg-config \
        meson \
        ninja-build \
        curl \
        wget \
        git \
        unzip \
        zip \
        tar \
        gzip \
        jq \
        bat \
        fzf \
        ripgrep \
        fd-find \
        htop \
        fastfetch \
        tldr \
        stow \
        tree \
        tmux \
        xdg-utils \
        dbus \
        xwayland \
        wayland-utils

    if [[ "$DISTRO" == "ubuntu" ]]; then
        pkg_install \
            g++ \
            xz-utils \
            ca-certificates \
            gnupg \
            lsb-release \
            software-properties-common \
            apt-transport-https \
            httpie \
            neofetch \
            dbus-user-session \
            pipewire \
            pipewire-pulse \
            wireplumber \
            libpipewire-0.3-dev \
            libwayland-dev \
            libwayland-client0
    else
        pkg_install \
            base-devel \
            ca-certificates \
            gnupg \
            httpie \
            neofetch \
            pipewire \
            pipewire-pulse \
            wireplumber \
            libwayland
    fi

    # bat is installed as batcat on Ubuntu — symlink it
    if has_cmd batcat && ! has_cmd bat; then
        run sudo ln -sf "$(which batcat)" /usr/local/bin/bat
        log_ok "Symlinked batcat → bat"
    fi

    # fd is installed as fdfind on Ubuntu — symlink it
    if has_cmd fdfind && ! has_cmd fd; then
        run sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
        log_ok "Symlinked fdfind → fd"
    fi

    log_ok "Base packages installed."
}

# ── Zsh + Oh My Zsh ───────────────────────────────────────────────────────────
_setup_zsh() {
    log_section "Zsh + Oh My Zsh"

    pkg_install zsh

    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_step "Installing Oh My Zsh..."
        run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log_info "Oh My Zsh already installed, skipping."
    fi

    # Plugins
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    log_step "Installing zsh-autosuggestions..."
    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
        run git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

    log_step "Installing zsh-syntax-highlighting..."
    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
        run git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

    log_step "Installing zsh-z (autojump alternative)..."
    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-z" ]] && \
        run git clone --depth=1 https://github.com/agkozak/zsh-z \
            "$ZSH_CUSTOM/plugins/zsh-z"

    # Write .zshrc
    log_step "Writing ~/.zshrc..."
    cat > "$HOME/.zshrc" <<'ZSHRC'
# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""   # Using Starship prompt instead

plugins=(
    git
    docker
    docker-compose
    kubectl
    helm
    golang
    rust
    node
    python
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-z
    terraform
    ansible
    gh
)

source $ZSH/oh-my-zsh.sh

# ── Starship Prompt ────────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Environment Variables ──────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="bat"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# ── Path additions ─────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.flutter/bin:$PATH"
export PATH="$HOME/Android/Sdk/platform-tools:$PATH"
export PATH="$HOME/Android/Sdk/cmdline-tools/latest/bin:$PATH"

# ── nvm (Node Version Manager) ─────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ── pyenv ──────────────────────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# ── uv ─────────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Go ─────────────────────────────────────────────────────────────────────────
export GOPATH="$HOME/go"
export GOROOT="/usr/local/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

# ── Aliases ────────────────────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias grep='grep --color=auto'
alias vim='nvim'
alias vi='nvim'
alias cat='bat'
alias top='btm'
alias find='fd'
alias lg='lazygit'
alias ldk='lazydocker'
alias k='kubectl'
alias tf='terraform'

# ── fzf ────────────────────────────────────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ── Zellij auto-start in terminal (optional — comment out to disable) ──────────
# if [[ -z "$ZELLIJ" ]]; then zellij; fi

ZSHRC

    # Set Zsh as default shell
    log_step "Setting Zsh as default shell..."
    run chsh -s "$(which zsh)" "$USER"

    # Install Starship
    log_step "Installing Starship prompt..."
    run curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

    # Starship config
    mkdir -p "$HOME/.config"
    cat > "$HOME/.config/starship.toml" <<'STARSHIP'
format = """
[╭─](bold green)$username$hostname$directory$git_branch$git_status$python$nodejs$golang$rust$docker_context
[╰─](bold green)$character"""

[username]
style_user = "bold cyan"
show_always = true

[hostname]
ssh_only = false
style = "bold blue"

[directory]
style = "bold purple"
truncation_length = 4
truncate_to_repo = true

[git_branch]
style = "bold yellow"

[git_status]
style = "bold red"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[python]
style = "bold yellow"

[nodejs]
style = "bold green"

[golang]
style = "bold cyan"

[rust]
style = "bold red"

[docker_context]
style = "bold blue"
STARSHIP

    log_ok "Zsh + Oh My Zsh + Starship configured."
}

# ── SSH Key ────────────────────────────────────────────────────────────────────
_setup_ssh() {
    log_section "SSH Key Setup"

    pkg_install openssh

    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        read -rp "$(echo -e "${YELLOW}Enter email for SSH key: ${RESET}")" ssh_email
        run ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519" -N ""
        log_ok "SSH key generated at ~/.ssh/id_ed25519"
    else
        log_info "SSH key already exists, skipping generation."
    fi

    # SSH config
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    cat > "$HOME/.ssh/config" <<'SSHCONF'
Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
SSHCONF
    chmod 600 "$HOME/.ssh/config"

    # Start ssh-agent (service is called sshd on Arch, ssh on Ubuntu)
    local ssh_svc="ssh"
    [[ "$DISTRO" == "arch" ]] && ssh_svc="sshd"
    run sudo systemctl enable "$ssh_svc"
    run sudo systemctl start "$ssh_svc"

    log_ok "SSH configured."
    log_info "Your public key (add to GitHub/GitLab):"
    cat "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || log_warn "Key not found (dry-run?)"
}

# ── UFW Firewall ───────────────────────────────────────────────────────────────
_setup_ufw() {
    log_section "UFW Firewall"

    pkg_install ufw

    run sudo ufw default deny incoming
    run sudo ufw default allow outgoing
    run sudo ufw allow ssh
    run sudo ufw allow 22/tcp
    # Tailscale interface
    run sudo ufw allow in on tailscale0
    # Enable without interactive prompt
    run sudo ufw --force enable

    log_ok "UFW configured: deny inbound, allow outbound, allow SSH."
    run sudo ufw status verbose
}

# ── Fail2ban ───────────────────────────────────────────────────────────────────
_setup_fail2ban() {
    log_section "Fail2ban"

    pkg_install fail2ban

    # Local jail config
    sudo tee /etc/fail2ban/jail.local > /dev/null <<'F2B'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
maxretry = 3
bantime  = 24h
F2B

    run sudo systemctl enable fail2ban
    run sudo systemctl restart fail2ban
    log_ok "Fail2ban installed and configured with SSH jail."
}

# ── Tailscale ──────────────────────────────────────────────────────────────────
_setup_tailscale() {
    log_section "Tailscale VPN"

    if ! has_cmd tailscale; then
        if [[ "$DISTRO" == "arch" ]]; then
            log_step "Installing Tailscale via yay..."
            run yay -S --noconfirm --needed tailscale
        else
            log_step "Adding Tailscale apt repo..."
            curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | \
                sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg > /dev/null
            curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | \
                sudo tee /etc/apt/sources.list.d/tailscale.list > /dev/null
            run sudo apt-get update
            pkg_install tailscale
        fi
    else
        log_info "Tailscale already installed."
    fi

    run sudo systemctl enable tailscaled
    run sudo systemctl start tailscaled
    log_ok "Tailscale installed. Run 'sudo tailscale up' to authenticate."
}

# ── Nerd Fonts ─────────────────────────────────────────────────────────────────
_setup_fonts() {
    log_section "Nerd Fonts"

    local FONTS_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONTS_DIR"

    local NF_VERSION="v3.2.1"
    local BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NF_VERSION}"

    local fonts=(
        "JetBrainsMono"
        "FiraCode"
        "Hack"
        "Meslo"
    )

    for font in "${fonts[@]}"; do
        if ! ls "$FONTS_DIR/${font}"*.ttf &>/dev/null 2>&1; then
            log_step "Downloading $font Nerd Font..."
            download "${BASE_URL}/${font}.zip" "/tmp/${font}.zip"
            run unzip -o "/tmp/${font}.zip" -d "$FONTS_DIR" '*.ttf' 2>/dev/null || true
            run rm -f "/tmp/${font}.zip"
        else
            log_info "$font already installed."
        fi
    done

    # fontconfig (fc-cache) is installed in _install_base_packages on both distros
    run fc-cache -fv
    log_ok "Nerd Fonts installed: JetBrainsMono, FiraCode, Hack, Meslo."
}
