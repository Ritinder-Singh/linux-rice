#!/usr/bin/env bash
# =============================================================================
# lib/utils.sh — Logging, colours, dry-run helpers
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

# ── apt wrapper ───────────────────────────────────────────────────────────────
apt_install() {
    log_step "Installing: $*"
    run sudo apt-get install -y --no-install-recommends "$@"
}

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
require_ubuntu_24() {
    if ! grep -q "Ubuntu 24" /etc/os-release 2>/dev/null; then
        log_warn "This script is designed for Ubuntu 24.04. Proceeding anyway, but things may break."
        confirm "Continue anyway?" || exit 1
    fi
}
