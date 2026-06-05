#!/usr/bin/env bash
# =============================================================================
# lib/security.sh — Security, Forensics & Networking Tools
# Covers: Nmap, Wireshark, Metasploit, Burp Suite, John, Hashcat,
#         Volatility 3, Autopsy/Sleuth Kit, Aircrack-ng, Gobuster, ffuf,
#         Nikto, sqlmap, netcat, tcpdump, Ghidra, Binwalk, Exiftool,
#         QEMU/KVM + Kali Linux VM
# =============================================================================

setup_security() {
    [[ "$DISTRO" == "arch" ]] && _setup_blackarch_repo
    _install_security_base
    _install_network_tools
    _install_password_tools
    _install_forensics_tools
    _install_web_tools
    _install_metasploit
    _install_burpsuite
    _install_ghidra
    _setup_kali_vm
}

# ── BlackArch repo — Arch only ────────────────────────────────────────────────
_setup_blackarch_repo() {
    if grep -q '\[blackarch\]' /etc/pacman.conf 2>/dev/null; then
        log_info "BlackArch repo already configured."
        return
    fi
    log_section "Setting up BlackArch repository"
    local strap_tmp
    strap_tmp=$(mktemp /tmp/strap.XXXXXX.sh)
    run curl -fsSL https://blackarch.org/strap.sh -o "$strap_tmp"
    run chmod +x "$strap_tmp"
    run sudo bash "$strap_tmp"
    run rm -f "$strap_tmp"
    log_ok "BlackArch repo configured."
}

# ── Security Base Tools ────────────────────────────────────────────────────────
_install_security_base() {
    log_section "Security Base Tools"

    if [[ "$DISTRO" == "arch" ]]; then
        run sudo pacman -S --noconfirm --needed \
            nmap openbsd-netcat tcpdump wireshark-qt aircrack-ng \
            binwalk perl-image-exiftool steghide foremost radare2 \
            ltrace strace 2>/dev/null || true
        run yay -S --noconfirm --needed python-pwntools 2>/dev/null || true
    else
        pkg_install \
            nmap \
            netcat-openbsd \
            tcpdump \
            wireshark \
            tshark \
            aircrack-ng \
            binwalk \
            exiftool \
            steghide \
            foremost \
            radare2 \
            ltrace \
            strace \
            pwntools 2>/dev/null || true
    fi

    # Add user to wireshark group (to capture without root)
    if getent group wireshark &>/dev/null; then
        run sudo usermod -aG wireshark "$USER"
        log_info "Added $USER to wireshark group."
    fi

    log_ok "Security base tools installed."
}

# ── Network Tools ─────────────────────────────────────────────────────────────
_install_network_tools() {
    log_section "Network Tools"

    if [[ "$DISTRO" == "arch" ]]; then
        run sudo pacman -S --noconfirm --needed \
            nmap masscan traceroute whois bind-tools net-tools ipcalc \
            openbsd-netcat socat proxychains-ng openvpn wireguard-tools \
            iptables nftables
    else
        pkg_install \
            nmap \
            masscan \
            traceroute \
            whois \
            dnsutils \
            net-tools \
            ipcalc \
            netcat-openbsd \
            socat \
            proxychains4 \
            openvpn \
            wireguard \
            iptables \
            nftables
    fi

    log_ok "Network tools installed."
}

# ── Password & Cracking Tools ──────────────────────────────────────────────────
_install_password_tools() {
    log_section "Password Tools (John the Ripper + Hashcat)"

    if [[ "$DISTRO" == "arch" ]]; then
        run sudo pacman -S --noconfirm --needed john hashcat
        return
    fi

    pkg_install john

    # Hashcat (latest from GitHub for better GPU support)
    if ! has_cmd hashcat; then
        local hc_version
        hc_version=$(curl -fsSL "https://api.github.com/repos/hashcat/hashcat/releases/latest" | jq -r '.tag_name' | tr -d 'v')
        download "https://github.com/hashcat/hashcat/releases/download/v${hc_version}/hashcat-${hc_version}.7z" \
            /tmp/hashcat.7z 2>/dev/null || {
            log_warn "Couldn't download Hashcat binary. Trying apt..."
            pkg_install hashcat
            return
        }
        pkg_install p7zip-full
        run 7z x /tmp/hashcat.7z -o/tmp/hashcat_extracted/
        run sudo install -m 755 "/tmp/hashcat_extracted/hashcat-${hc_version}/hashcat.bin" /usr/local/bin/hashcat
        run rm -rf /tmp/hashcat.7z /tmp/hashcat_extracted
    fi

    log_ok "John the Ripper + Hashcat installed."
}

# ── Forensics Tools ────────────────────────────────────────────────────────────
_install_forensics_tools() {
    log_section "Forensics Tools (Volatility 3, Autopsy, Sleuth Kit)"

    # Sleuth Kit
    if [[ "$DISTRO" == "arch" ]]; then
        run sudo pacman -S --noconfirm --needed sleuthkit autopsy 2>/dev/null || \
            run yay -S --noconfirm --needed autopsy 2>/dev/null || true
    else
        pkg_install sleuthkit autopsy
    fi

    # Volatility 3 (Python-based, install via uv/pip)
    if ! has_cmd vol; then
        log_step "Installing Volatility 3..."
        run git clone --depth=1 https://github.com/volatilityfoundation/volatility3.git \
            "$HOME/tools/volatility3" 2>/dev/null || {
            mkdir -p "$HOME/tools"
            run git clone --depth=1 https://github.com/volatilityfoundation/volatility3.git \
                "$HOME/tools/volatility3"
        }
        run pip3 install -r "$HOME/tools/volatility3/requirements.txt" 2>/dev/null || \
            run "$HOME/.local/bin/uv" pip install --system \
                -r "$HOME/tools/volatility3/requirements.txt" 2>/dev/null || true

        # Create a wrapper script
        cat > /tmp/vol <<VOLSCRIPT
#!/usr/bin/env bash
exec python3 "$HOME/tools/volatility3/vol.py" "\$@"
VOLSCRIPT
        run sudo install -m 755 /tmp/vol /usr/local/bin/vol
        run rm -f /tmp/vol
    fi

    log_ok "Forensics tools installed."
}

# ── Web Hacking Tools ──────────────────────────────────────────────────────────
_install_web_tools() {
    log_section "Web Hacking Tools (Gobuster, ffuf, Nikto, sqlmap)"

    # Gobuster (Go binary)
    if ! has_cmd gobuster && has_cmd go; then
        log_step "Installing Gobuster..."
        run go install github.com/OJ/gobuster/v3@latest
    elif ! has_cmd gobuster; then
        if [[ "$DISTRO" == "arch" ]]; then
            run sudo pacman -S --noconfirm --needed gobuster 2>/dev/null || \
                run go install github.com/OJ/gobuster/v3@latest 2>/dev/null || true
        else
            pkg_install gobuster 2>/dev/null || log_warn "gobuster not in apt; install Go first."
        fi
    fi

    # ffuf (Go binary)
    if ! has_cmd ffuf && has_cmd go; then
        log_step "Installing ffuf..."
        run go install github.com/ffuf/ffuf/v2@latest
    fi

    # Nikto (Perl-based)
    if [[ "$DISTRO" == "arch" ]]; then
        run sudo pacman -S --noconfirm --needed nikto
    else
        pkg_install nikto
    fi

    # sqlmap
    if ! has_cmd sqlmap; then
        log_step "Installing sqlmap..."
        run git clone --depth=1 https://github.com/sqlmapproject/sqlmap.git \
            "$HOME/tools/sqlmap" 2>/dev/null || {
            mkdir -p "$HOME/tools"
            run git clone --depth=1 https://github.com/sqlmapproject/sqlmap.git "$HOME/tools/sqlmap"
        }
        cat > /tmp/sqlmap_wrapper <<SQLMAP
#!/usr/bin/env bash
exec python3 "$HOME/tools/sqlmap/sqlmap.py" "\$@"
SQLMAP
        run sudo install -m 755 /tmp/sqlmap_wrapper /usr/local/bin/sqlmap
        run rm -f /tmp/sqlmap_wrapper
    fi

    # WordLists (SecLists)
    if [[ ! -d "/usr/share/seclists" ]]; then
        log_step "Installing SecLists wordlists..."
        run sudo git clone --depth=1 https://github.com/danielmiessler/SecLists.git /usr/share/seclists
    fi

    log_ok "Web hacking tools installed."
}

# ── Metasploit Framework ───────────────────────────────────────────────────────
_install_metasploit() {
    log_section "Metasploit Framework"

    if ! has_cmd msfconsole; then
        log_step "Installing Metasploit Framework..."
        run curl -fsSL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb | \
            sudo bash
    else
        log_info "Metasploit already installed."
    fi

    log_ok "Metasploit installed. Run 'msfconsole' to start."
}

# ── Burp Suite Community ───────────────────────────────────────────────────────
_install_burpsuite() {
    log_section "Burp Suite Community Edition"

    if [[ ! -f "/usr/local/bin/burpsuite" ]]; then
        log_step "Downloading Burp Suite Community..."

        # Fetch latest download URL from PortSwigger API
        local burp_url
        burp_url=$(curl -fsSL "https://portswigger.net/burp/releases/data?product=community&edition=&platform=Linux" | \
            jq -r '.ResultSet.Results[0].releases[0].items[] | select(.platform=="Linux") | .fileUrl' 2>/dev/null)

        if [[ -z "$burp_url" || "$burp_url" == "null" ]]; then
            # Fallback to known stable release
            burp_url="https://portswigger.net/burp/releases/download?product=community&version=2024.9.4&type=Linux"
        fi

        download "$burp_url" /tmp/burpsuite_installer.sh
        run chmod +x /tmp/burpsuite_installer.sh

        # Run headless installer
        log_step "Running Burp Suite installer (headless)..."
        run sudo /tmp/burpsuite_installer.sh -q -dir /opt/burpsuite
        run rm -f /tmp/burpsuite_installer.sh

        # Create launcher
        cat > /tmp/burpsuite_launcher <<'BURP'
#!/usr/bin/env bash
exec /opt/burpsuite/BurpSuiteCommunity/BurpSuiteCommunity "$@"
BURP
        run sudo install -m 755 /tmp/burpsuite_launcher /usr/local/bin/burpsuite
        run rm -f /tmp/burpsuite_launcher
    else
        log_info "Burp Suite already installed."
    fi

    # Desktop entry
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/burpsuite.desktop" <<DESKTOP
[Desktop Entry]
Name=Burp Suite Community
Exec=burpsuite %U
Icon=/opt/burpsuite/BurpSuiteCommunity/icon.png
Type=Application
Categories=Development;Security;
Comment=Web security testing tool
DESKTOP

    log_ok "Burp Suite Community installed."
}

# ── Ghidra (NSA Reverse Engineering Tool) ─────────────────────────────────────
_install_ghidra() {
    log_section "Ghidra (Reverse Engineering)"

    if [[ ! -d "$HOME/tools/ghidra" ]]; then
        log_step "Downloading Ghidra..."
        local ghidra_version
        ghidra_version=$(curl -fsSL "https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest" | \
            jq -r '.tag_name' | tr -d 'Ghidra_')
        local ghidra_file="ghidra_${ghidra_version}_PUBLIC"

        download "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${ghidra_version}_build/${ghidra_file}.zip" \
            /tmp/ghidra.zip
        mkdir -p "$HOME/tools"
        run unzip -o /tmp/ghidra.zip -d "$HOME/tools/"
        run mv "$HOME/tools/${ghidra_file}" "$HOME/tools/ghidra"
        run rm -f /tmp/ghidra.zip

        # Launcher wrapper
        cat > /tmp/ghidra_wrapper <<GHIDRA
#!/usr/bin/env bash
exec "$HOME/tools/ghidra/ghidraRun" "\$@"
GHIDRA
        run sudo install -m 755 /tmp/ghidra_wrapper /usr/local/bin/ghidra
        run rm -f /tmp/ghidra_wrapper
    else
        log_info "Ghidra already installed."
    fi

    log_ok "Ghidra installed. Run 'ghidra' to start."
}

# ── Kali Linux VM (QEMU/KVM) ──────────────────────────────────────────────────
_setup_kali_vm() {
    log_section "Kali Linux VM (QEMU/KVM)"

    # Install QEMU/KVM and virt-manager
    if [[ "$DISTRO" == "arch" ]]; then
        run sudo pacman -S --noconfirm --needed \
            qemu-full virt-manager libvirt ovmf bridge-utils dnsmasq
    else
        pkg_install \
            qemu-kvm \
            libvirt-daemon-system \
            libvirt-clients \
            bridge-utils \
            virtinst \
            virt-manager \
            virt-viewer \
            ovmf \
            qemu-system-x86 \
            cpu-checker
    fi

    # Add user to required groups
    run sudo usermod -aG libvirt "$USER"
    run sudo usermod -aG kvm "$USER"

    run sudo systemctl enable libvirtd
    run sudo systemctl start libvirtd

    # Check if KVM is available
    if ! kvm-ok &>/dev/null; then
        log_warn "KVM acceleration not available (expected in VirtualBox VM)."
        log_warn "Kali will run via QEMU software emulation — it will be slow."
        log_warn "For best performance, run this on bare metal with VT-x/AMD-V enabled."
    fi

    # Download Kali Linux ISO
    local KALI_DIR="$HOME/VMs/kali"
    mkdir -p "$KALI_DIR"

    local KALI_ISO="$KALI_DIR/kali-linux.iso"
    if [[ ! -f "$KALI_ISO" ]]; then
        log_step "Downloading Kali Linux 2024 ISO (~4GB — this will take a while)..."
        log_info "Kali 2024.4 amd64 netinstaller will be downloaded."
        download "https://cdimage.kali.org/kali-2024.4/kali-linux-2024.4-installer-amd64.iso" \
            "$KALI_ISO"
        log_ok "Kali ISO downloaded to $KALI_ISO"
    else
        log_info "Kali ISO already exists at $KALI_ISO"
    fi

    # Create the Kali VM disk image
    local KALI_DISK="$KALI_DIR/kali-disk.qcow2"
    if [[ ! -f "$KALI_DISK" ]]; then
        log_step "Creating 80GB Kali VM disk image..."
        run qemu-img create -f qcow2 "$KALI_DISK" 80G
    fi

    # Define the VM via virt-install
    if ! run virsh dominfo kali-linux &>/dev/null 2>&1; then
        log_step "Defining Kali Linux VM..."
        run virt-install \
            --name kali-linux \
            --ram 4096 \
            --vcpus 4 \
            --disk path="$KALI_DISK",format=qcow2 \
            --cdrom "$KALI_ISO" \
            --os-variant debian12 \
            --network network=default \
            --graphics spice \
            --video qxl \
            --channel spicevmc \
            --noautoconsole \
            --boot cdrom,hd 2>/dev/null || \
            log_warn "VM definition via virt-install failed. Open virt-manager to set it up manually."
    else
        log_info "Kali VM already defined."
    fi

    log_ok "QEMU/KVM + Kali Linux VM set up."
    log_info "Open virt-manager to start the VM and complete Kali installation."
    log_info "VM files: $KALI_DIR"
    log_warn "In VirtualBox: nested virtualisation must be enabled for KVM to work."
    log_warn "Enable via: VBoxManage modifyvm <vm-name> --nested-hw-virt on"
}
