#!/usr/bin/env bash
# =============================================================================
# lib/dev.sh — Full Dev & DevOps Stack
# Covers: nvm/Node, pyenv/Python, uv, Go, Rust, Flutter, Android SDK,
#         Docker, kubectl, Helm, k9s, Terraform, Ansible, GitHub CLI,
#         lazygit, lazydocker, act, Floci, jq, httpie
# =============================================================================

setup_dev() {
    _install_git_tools
    _install_node
    _install_python
    _install_go
    _install_rust
    _install_flutter_android
    _install_docker
    _install_kubernetes_tools
    _install_terraform_ansible
    _install_github_cli
    _install_lazy_tools
    _install_act
    _install_floci
    _install_matugen_if_needed
}

# ── Git + GitHub CLI ───────────────────────────────────────────────────────────
_install_git_tools() {
    log_section "Git Setup"

    pkg_install git git-lfs

    run git lfs install

    read -rp "$(echo -e "${YELLOW}Git username (for global config): ${RESET}")" git_name
    read -rp "$(echo -e "${YELLOW}Git email (for global config): ${RESET}")" git_email

    if [[ -n "$git_name" ]]; then
        run git config --global user.name "$git_name"
        run git config --global user.email "$git_email"
    fi

    run git config --global init.defaultBranch main
    run git config --global core.editor nvim
    run git config --global pull.rebase false
    run git config --global core.autocrlf input
    run git config --global color.ui auto
    run git config --global alias.lg "log --oneline --graph --decorate --all"
    run git config --global alias.st "status -sb"

    log_ok "Git configured."
}

# ── Node.js via nvm ────────────────────────────────────────────────────────────
_install_node() {
    log_section "Node.js (via nvm)"

    if [[ ! -d "$HOME/.nvm" ]]; then
        log_step "Installing nvm..."
        local nvm_version
        nvm_version=$(curl -fsSL "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | jq -r '.tag_name')
        run curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash
    else
        log_info "nvm already installed."
    fi

    # Load nvm in current shell
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    log_step "Installing Node.js LTS..."
    run nvm install --lts
    run nvm use --lts
    run nvm alias default 'lts/*'

    log_step "Installing global npm packages..."
    run npm install -g pnpm typescript tsx ts-node eslint prettier nodemon pm2

    log_ok "Node.js LTS + pnpm + global tools installed."
}

# ── Python via pyenv + uv ──────────────────────────────────────────────────────
_install_python() {
    log_section "Python (via pyenv + uv)"

    # pyenv build dependencies
    if [[ "$DISTRO" == "arch" ]]; then
        pkg_install \
            openssl \
            zlib \
            bzip2 \
            readline \
            sqlite \
            ncurses \
            libxml2 \
            libxmlsec1 \
            libffi \
            xz \
            tk
    else
        pkg_install \
            libssl-dev \
            zlib1g-dev \
            libbz2-dev \
            libreadline-dev \
            libsqlite3-dev \
            libncursesw5-dev \
            libxml2-dev \
            libxmlsec1-dev \
            libffi-dev \
            liblzma-dev \
            tk-dev
    fi

    if [[ ! -d "$HOME/.pyenv" ]]; then
        log_step "Installing pyenv..."
        run curl -fsSL https://pyenv.run | bash
    else
        log_info "pyenv already installed."
    fi

    # Load pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)" 2>/dev/null || true

    log_step "Installing Python 3.12 (latest stable)..."
    run pyenv install -s 3.12
    run pyenv global 3.12

    # uv — modern Python package manager
    log_step "Installing uv..."
    run curl -fsSL https://astral.sh/uv/install.sh | sh

    # Core ML/data science packages (global via uv)
    log_step "Installing ML/DS packages via uv..."
    run "$HOME/.local/bin/uv" pip install --system \
        numpy \
        pandas \
        matplotlib \
        scikit-learn \
        torch \
        torchvision \
        jupyter \
        ipykernel \
        black \
        ruff \
        mypy \
        pytest 2>/dev/null || \
        log_warn "Some ML packages may need manual install after full GPU driver setup."

    log_ok "Python 3.12 + pyenv + uv installed."
}

# ── Go ────────────────────────────────────────────────────────────────────────
_install_go() {
    log_section "Go"

    if ! has_cmd go; then
        log_step "Fetching latest Go version..."
        local go_version
        go_version=$(curl -fsSL "https://go.dev/dl/?mode=json" | jq -r '.[0].version')
        download "https://go.dev/dl/${go_version}.linux-amd64.tar.gz" /tmp/go.tar.gz

        log_step "Installing Go ${go_version}..."
        run sudo rm -rf /usr/local/go
        run sudo tar -C /usr/local -xzf /tmp/go.tar.gz
        run rm -f /tmp/go.tar.gz
    else
        log_info "Go already installed: $(go version)"
    fi

    export GOPATH="$HOME/go"
    export GOROOT="/usr/local/go"
    export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
    mkdir -p "$GOPATH/bin" "$GOPATH/src" "$GOPATH/pkg"

    log_ok "Go installed."
}

# ── Rust ──────────────────────────────────────────────────────────────────────
_install_rust() {
    log_section "Rust (via rustup)"

    if ! has_cmd rustup; then
        log_step "Installing Rust via rustup..."
        run curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
    else
        log_info "Rust already installed."
        run rustup update
    fi

    export PATH="$HOME/.cargo/bin:$PATH"

    # Common Rust tools
    log_step "Installing Rust tools..."
    run cargo install cargo-watch cargo-edit cargo-audit cargo-expand 2>/dev/null || \
        log_warn "Some Rust tools failed — run manually after reboot."

    # Install Matugen now that Rust is ready
    if [[ -f /tmp/.install_matugen_later ]]; then
        log_step "Installing Matugen (deferred from desktop setup)..."
        run cargo install matugen
        rm -f /tmp/.install_matugen_later
    fi

    log_ok "Rust + cargo tools installed."
}

# ── Flutter + Android SDK ──────────────────────────────────────────────────────
_install_flutter_android() {
    log_section "Flutter + Android SDK"

    pkg_install openjdk-17-jdk openjdk-21-jdk

    if [[ "$DISTRO" == "ubuntu" ]]; then
        pkg_install libglu1-mesa lib32stdc++6 libc6-i386
        run sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java 2>/dev/null || \
            log_warn "Could not set JDK 17 as default via update-alternatives."
    else
        pkg_install mesa lib32-gcc-libs
        # Switch to JDK 17 on Arch via archlinux-java
        run sudo archlinux-java set java-17-openjdk 2>/dev/null || \
            log_warn "Could not set JDK 17 as default — run: sudo archlinux-java set java-17-openjdk"
    fi

    # Android SDK via command-line tools
    local ANDROID_HOME="$HOME/Android/Sdk"
    mkdir -p "$ANDROID_HOME/cmdline-tools"

    if [[ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]]; then
        log_step "Downloading Android command-line tools..."
        download "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
            /tmp/cmdline-tools.zip
        run unzip -o /tmp/cmdline-tools.zip -d /tmp/cmdline-tools/
        run mv /tmp/cmdline-tools/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
        run rm -f /tmp/cmdline-tools.zip
    fi

    export ANDROID_HOME="$HOME/Android/Sdk"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

    log_step "Accepting Android licenses..."
    run yes | sdkmanager --licenses 2>/dev/null || log_warn "License acceptance may need manual run."

    log_step "Installing Android SDK components..."
    run sdkmanager \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "emulator" \
        "system-images;android-34;google_apis;x86_64" 2>/dev/null || \
        log_warn "Some SDK packages may need to be installed manually via Android Studio."

    # Flutter
    local FLUTTER_DIR="$HOME/.flutter"
    if [[ ! -d "$FLUTTER_DIR" ]]; then
        log_step "Cloning Flutter SDK (stable)..."
        run git clone --depth=1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
    else
        log_info "Flutter already cloned."
        run git -C "$FLUTTER_DIR" pull --ff-only
    fi

    export PATH="$FLUTTER_DIR/bin:$PATH"

    log_step "Running flutter doctor..."
    run flutter doctor --android-licenses 2>/dev/null || true
    run flutter doctor 2>/dev/null || true

    log_step "Installing common Flutter packages..."
    run flutter pub global activate dart_style
    run flutter pub global activate flutterfire_cli 2>/dev/null || true

    log_ok "Flutter + Android SDK installed."
    log_info "Install Android Studio from the editors section to complete the setup."
}

# ── Docker ────────────────────────────────────────────────────────────────────
_install_docker() {
    log_section "Docker + Docker Compose"

    if ! has_cmd docker; then
        if [[ "$DISTRO" == "arch" ]]; then
            log_step "Installing Docker via yay..."
            run yay -S --noconfirm --needed docker docker-compose
        else
            log_step "Adding Docker apt repository..."
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
                sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            run sudo apt-get update
            pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        fi
    else
        log_info "Docker already installed."
    fi

    # Add user to docker group
    if ! groups "$USER" | grep -q docker; then
        run sudo usermod -aG docker "$USER"
        log_info "Added $USER to docker group (re-login required)."
    fi

    run sudo systemctl enable docker
    run sudo systemctl start docker

    log_ok "Docker + Docker Compose installed."
}

# ── Kubernetes Tools ──────────────────────────────────────────────────────────
_install_kubernetes_tools() {
    log_section "Kubernetes: kubectl + Helm + k9s"

    # kubectl
    if ! has_cmd kubectl; then
        log_step "Installing kubectl..."
        local k8s_version
        k8s_version=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
        download "https://dl.k8s.io/release/${k8s_version}/bin/linux/amd64/kubectl" /tmp/kubectl
        run sudo install -m 755 /tmp/kubectl /usr/local/bin/kubectl
        run rm -f /tmp/kubectl
    fi

    # Helm
    if ! has_cmd helm; then
        log_step "Installing Helm..."
        run curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

    # k9s
    if ! has_cmd k9s; then
        log_step "Installing k9s..."
        local k9s_version
        k9s_version=$(curl -fsSL "https://api.github.com/repos/derailed/k9s/releases/latest" | jq -r '.tag_name')
        download "https://github.com/derailed/k9s/releases/download/${k9s_version}/k9s_Linux_amd64.tar.gz" \
            /tmp/k9s.tar.gz
        run tar -xzf /tmp/k9s.tar.gz -C /tmp/
        run sudo install -m 755 /tmp/k9s /usr/local/bin/k9s
        run rm -f /tmp/k9s.tar.gz /tmp/k9s
    fi

    log_ok "kubectl, Helm, k9s installed."
}

# ── Terraform + Ansible ───────────────────────────────────────────────────────
_install_terraform_ansible() {
    log_section "Terraform + Ansible"

    # Terraform
    if ! has_cmd terraform; then
        if [[ "$DISTRO" == "arch" ]]; then
            log_step "Installing Terraform via yay..."
            run yay -S --noconfirm --needed terraform
        else
            log_step "Adding HashiCorp apt repo..."
            wget -qO- https://apt.releases.hashicorp.com/gpg | \
                sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
                sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
            run sudo apt-get update
            pkg_install terraform
        fi
    fi

    # Ansible
    if ! has_cmd ansible; then
        if [[ "$DISTRO" == "arch" ]]; then
            log_step "Installing Ansible via pacman..."
            run sudo pacman -S --noconfirm --needed ansible
        else
            log_step "Installing Ansible..."
            run sudo add-apt-repository -y ppa:ansible/ansible
            run sudo apt-get update
            pkg_install ansible ansible-lint
        fi
    fi

    log_ok "Terraform + Ansible installed."
}

# ── GitHub CLI ────────────────────────────────────────────────────────────────
_install_github_cli() {
    log_section "GitHub CLI (gh)"

    if ! has_cmd gh; then
        if [[ "$DISTRO" == "arch" ]]; then
            log_step "Installing GitHub CLI via pacman..."
            run sudo pacman -S --noconfirm --needed github-cli
        else
            log_step "Adding GitHub CLI apt repo..."
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
                sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" | \
                sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            run sudo apt-get update
            pkg_install gh
        fi
    fi

    log_ok "GitHub CLI installed. Run 'gh auth login' to authenticate."
}

# ── Lazy Tools: lazygit + lazydocker ──────────────────────────────────────────
_install_lazy_tools() {
    log_section "lazygit + lazydocker"

    # lazygit
    if ! has_cmd lazygit; then
        local lg_version
        lg_version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r '.tag_name' | tr -d 'v')
        download "https://github.com/jesseduffield/lazygit/releases/download/v${lg_version}/lazygit_${lg_version}_Linux_x86_64.tar.gz" \
            /tmp/lazygit.tar.gz
        run tar -xzf /tmp/lazygit.tar.gz -C /tmp/
        run sudo install -m 755 /tmp/lazygit /usr/local/bin/lazygit
        run rm -f /tmp/lazygit.tar.gz /tmp/lazygit
    fi

    # lazydocker
    if ! has_cmd lazydocker; then
        local ldk_version
        ldk_version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | jq -r '.tag_name' | tr -d 'v')
        download "https://github.com/jesseduffield/lazydocker/releases/download/v${ldk_version}/lazydocker_${ldk_version}_Linux_x86_64.tar.gz" \
            /tmp/lazydocker.tar.gz
        run tar -xzf /tmp/lazydocker.tar.gz -C /tmp/
        run sudo install -m 755 /tmp/lazydocker /usr/local/bin/lazydocker
        run rm -f /tmp/lazydocker.tar.gz /tmp/lazydocker
    fi

    log_ok "lazygit + lazydocker installed."
}

# ── act (GitHub Actions locally) ──────────────────────────────────────────────
_install_act() {
    log_section "act (GitHub Actions locally)"

    if ! has_cmd act; then
        run curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
    fi

    log_ok "act installed."
}

# ── Floci (local AWS emulator) ─────────────────────────────────────────────────
_install_floci() {
    log_section "Floci (Local AWS Emulator)"

    if ! has_cmd floci; then
        log_step "Installing Floci from GitHub..."
        local floci_version
        floci_version=$(curl -fsSL "https://api.github.com/repos/localstack/floci/releases/latest" 2>/dev/null | jq -r '.tag_name' 2>/dev/null)

        if [[ -z "$floci_version" || "$floci_version" == "null" ]]; then
            log_warn "Could not fetch Floci version from GitHub. Trying pip install..."
            run "$HOME/.local/bin/uv" pip install --system floci 2>/dev/null || \
                log_warn "Floci install failed. Install manually: https://github.com/localstack/floci"
        else
            download "https://github.com/localstack/floci/releases/download/${floci_version}/floci-linux-amd64" \
                /tmp/floci
            run sudo install -m 755 /tmp/floci /usr/local/bin/floci
            run rm -f /tmp/floci
            log_ok "Floci installed."
        fi
    else
        log_info "Floci already installed."
    fi
}

# ── Matugen post-Rust install ──────────────────────────────────────────────────
_install_matugen_if_needed() {
    if [[ -f /tmp/.install_matugen_later ]] && has_cmd cargo; then
        log_step "Installing Matugen (was deferred, Rust now available)..."
        run cargo install matugen
        rm -f /tmp/.install_matugen_later
        log_ok "Matugen installed."
    fi
}
