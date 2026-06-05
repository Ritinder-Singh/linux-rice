#!/usr/bin/env bash
# =============================================================================
# lib/utils.sh — Logging, colours, dry-run helpers, distro abstraction
# =============================================================================

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Dry-run flag (set by install.sh if --dry-run passed) ─────────────────────
DRY_RUN=${DRY_RUN:-false}

# ── Logging helpers ───────────────────────────────────────────────────────────
log_info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
log_section() { echo -e "\n${BOLD}${MAGENTA}══════════════════════════════════════════${RESET}"; \
                echo -e "${BOLD}${MAGENTA}  $*${RESET}"; \
                echo -e "${BOLD}${MAGENTA}══════════════════════════════════════════${RESET}\n"; }
log_step()    { echo -e "${CYAN}  ➜${RESET}  $*"; }

# ── Command wrapper — respects --dry-run ──────────────────────────────────────
# Usage: run <command and args>
run() {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY-RUN]${RESET} $*"
    else
        "$@"
    fi
}

# ── Distro detection ──────────────────────────────────────────────────────────
detect_distro() {
    local id=""
    if [[ -f /etc/os-release ]]; then
        id=$(. /etc/os-release && echo "${ID:-}")
    fi
    case "$id" in
        ubuntu)                    DISTRO="ubuntu" ;;
        arch|endeavouros|manjaro)  DISTRO="arch"   ;;
        *)
            log_warn "Unrecognised distro '$id'. Defaulting to ubuntu mode."
            DISTRO="ubuntu"
            ;;
    esac
    export DISTRO
    log_info "Distro       : $DISTRO (ID=$id)"
}

# ── Package-name mapping ──────────────────────────────────────────────────────
# resolve_pkg <generic-name>  →  prints the distro-correct package name,
# or prints nothing (empty) if the package should be skipped on this distro.
resolve_pkg() {
    local pkg="$1"
    if [[ "$DISTRO" == "arch" ]]; then
        case "$pkg" in
            policykit-1)            echo "polkit"             ; return ;;
            netcat-openbsd)         echo "openbsd-netcat"     ; return ;;
            fd-find)                echo "fd"                 ; return ;;
            build-essential)        echo "base-devel"         ; return ;;
            python3-pynvim)         echo "python-pynvim"      ; return ;;
            libinput-dev)           echo "libinput"           ; return ;;
            libseat-dev)            echo "seatd"              ; return ;;
            network-manager)        echo "networkmanager"     ; return ;;
            openjdk-17-jdk)         echo "jdk17-openjdk"      ; return ;;
            openjdk-21-jdk)         echo "jdk21-openjdk"      ; return ;;
            fonts-wine)             echo ""                   ; return ;; # skip
            v4l2loopback-dkms)      echo "v4l2loopback-dkms"  ; return ;;
            xdg-desktop-portal-wlr) echo "xdg-desktop-portal-wlr" ; return ;;
            *)                      echo "$pkg"               ; return ;;
        esac
    else
        echo "$pkg"
    fi
}

# ── Universal package installer ────────────────────────────────────────────────
# Resolves each package name for the current distro, skips empty mappings,
# then calls the appropriate package manager.
pkg_install() {
    local resolved=()
    local pkg mapped
    for pkg in "$@"; do
        mapped=$(resolve_pkg "$pkg")
        if [[ -n "$mapped" ]]; then
            resolved+=("$mapped")
        else
            log_info "Skipping package '$pkg' (not needed on $DISTRO)"
        fi
    done

    [[ ${#resolved[@]} -eq 0 ]] && return 0

    log_step "Installing: ${resolved[*]}"
    if [[ "$DISTRO" == "arch" ]]; then
        if has_cmd yay; then
            run yay -S --noconfirm --needed "${resolved[@]}"
        else
            run sudo pacman -S --noconfirm --needed "${resolved[@]}"
        fi
    else
        run sudo apt-get install -y --no-install-recommends "${resolved[@]}"
    fi
}

# Keep apt_install as a thin alias so any call sites not yet converted still work
apt_install() { pkg_install "$@"; }

# ── Check if a command exists ─────────────────────────────────────────────────
has_cmd() { command -v "$1" &>/dev/null; }

# ── Check if a package is installed ──────────────────────────────────────────
apt_installed() { dpkg -s "$1" &>/dev/null; }

# ── Require root ──────────────────────────────────────────────────────────────
require_not_root() {
    if [[ "$EUID" -eq 0 ]]; then
        log_error "Do not run this script as root. Run as your normal user (sudo will be called when needed)."
        exit 1
    fi
}

# ── Confirm prompt ────────────────────────────────────────────────────────────
confirm() {
    local prompt="${1:-Continue?}"
    read -rp "$(echo -e "${YELLOW}${prompt} [y/N]: ${RESET}")" answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ── Add a line to a file only if it doesn't already exist ────────────────────
append_once() {
    local line="$1" file="$2"
    grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# ── Download helper ───────────────────────────────────────────────────────────
download() {
    local url="$1" dest="$2"
    log_step "Downloading: $url"
    run curl -fsSL "$url" -o "$dest"
}

# ── Architecture detection ────────────────────────────────────────────────────
detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  ARCH_ALIAS="amd64" ;;
        aarch64) ARCH_ALIAS="arm64" ;;
        *)        log_error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    export ARCH ARCH_ALIAS
}

# ── OS version check ──────────────────────────────────────────────────────────
require_supported_distro() {
    if [[ -z "${DISTRO:-}" ]]; then
        detect_distro
    fi
    case "$DISTRO" in
        ubuntu|arch) ;;
        *)
            log_warn "Unsupported distro. Proceeding in ubuntu mode."
            confirm "Continue anyway?" || exit 1
            ;;
    esac
}

# Keep old name for callers that haven't been updated yet
require_ubuntu_24() {
    if [[ "$DISTRO" == "ubuntu" ]]; then
        if ! grep -q "Ubuntu 24" /etc/os-release 2>/dev/null; then
            log_warn "This script targets Ubuntu 24.04. Proceeding anyway."
            confirm "Continue anyway?" || exit 1
        fi
    fi
}
