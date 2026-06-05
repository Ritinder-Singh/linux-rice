#!/usr/bin/env bash
# =============================================================================
#
#  ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗
#  ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
#  ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝     ███████╗█████╗     ██║   ██║   ██║██████╔╝
#  ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗     ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
#  ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗    ███████║███████╗   ██║   ╚██████╔╝██║
#  ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝
#
#  Personal Linux Setup Script — Ubuntu 24.04 LTS & Arch/EndeavourOS
#  Target: x86_64 (VirtualBox / bare metal)
#
#  Usage:
#    ./install.sh              Run full setup
#    ./install.sh --dry-run    Print all actions without executing
#    ./install.sh --only dev   Run only the dev section
#    ./install.sh --skip gaming,security   Run everything except specified sections
#    ./install.sh --help       Show this help
#
#  Sections: system, gpu, desktop, dev, editors, security, gaming, content
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# ── Source all library files ──────────────────────────────────────────────────
source "$LIB_DIR/utils.sh"
source "$LIB_DIR/system.sh"
source "$LIB_DIR/gpu.sh"
source "$LIB_DIR/desktop.sh"
source "$LIB_DIR/dev.sh"
source "$LIB_DIR/editors.sh"
source "$LIB_DIR/security.sh"
source "$LIB_DIR/gaming.sh"
source "$LIB_DIR/content.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────
DRY_RUN=false
ONLY_SECTION=""
SKIP_SECTIONS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            export DRY_RUN
            log_warn "DRY RUN MODE — no changes will be made."
            shift ;;
        --only)
            ONLY_SECTION="$2"
            shift 2 ;;
        --skip)
            SKIP_SECTIONS="$2"
            shift 2 ;;
        --help|-h)
            sed -n '2,20p' "$0"
            exit 0 ;;
        *)
            log_error "Unknown argument: $1"
            exit 1 ;;
    esac
done

# ── Helper: should we run this section? ───────────────────────────────────────
should_run() {
    local section="$1"
    # If --only specified, run only that section
    if [[ -n "$ONLY_SECTION" ]]; then
        [[ "$ONLY_SECTION" == "$section" ]] && return 0 || return 1
    fi
    # If --skip specified, skip those sections
    if [[ -n "$SKIP_SECTIONS" ]]; then
        IFS=',' read -ra skips <<< "$SKIP_SECTIONS"
        for skip in "${skips[@]}"; do
            [[ "$skip" == "$section" ]] && return 1
        done
    fi
    return 0
}

# ── Pre-flight checks ─────────────────────────────────────────────────────────
preflight() {
    log_section "Pre-flight Checks"

    require_not_root
    detect_arch
    detect_distro
    require_ubuntu_24

    log_info "Architecture : $ARCH ($ARCH_ALIAS)"
    log_info "Distro       : $DISTRO"
    log_info "User         : $USER"
    log_info "Home         : $HOME"
    log_info "Dry run      : $DRY_RUN"
    [[ -n "$ONLY_SECTION" ]] && log_info "Only section : $ONLY_SECTION"
    [[ -n "$SKIP_SECTIONS" ]] && log_info "Skipping     : $SKIP_SECTIONS"
    echo ""

    # Sudo keepalive — refresh sudo timestamp periodically so we don't time out
    # during long installs
    sudo -v
    (while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done) &
    SUDO_KEEPALIVE_PID=$!
    export SUDO_KEEPALIVE_PID

    log_ok "Pre-flight checks passed."
}

# ── Cleanup on exit ───────────────────────────────────────────────────────────
cleanup() {
    local exit_code=$?
    # Kill sudo keepalive
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
    # Clean temp files
    rm -f /tmp/.install_matugen_later 2>/dev/null || true

    if [[ $exit_code -ne 0 ]]; then
        echo ""
        log_error "Setup failed with exit code $exit_code."
        log_error "Check the output above for the error."
        log_info  "You can re-run the script — it is safe to re-run."
        log_info  "Or run a specific section: ./install.sh --only <section>"
    fi
}
trap cleanup EXIT

# ── Progress log ──────────────────────────────────────────────────────────────
LOG_FILE="$HOME/linux-setup-$(date +%Y%m%d_%H%M%S).log"
# Tee all output to a log file
exec > >(tee -a "$LOG_FILE") 2>&1
log_info "Full log: $LOG_FILE"

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}${MAGENTA}"
    echo "  Personal Linux Setup — Ubuntu 24.04 LTS & Arch/EndeavourOS"
    echo "  Starting at $(date)"
    echo -e "${RESET}"

    preflight

    # ── Sections (in order) ────────────────────────────────────────────────────
    if should_run "system"; then
        setup_system
    fi

    if should_run "gpu"; then
        install_gpu_drivers
    fi

    if should_run "desktop"; then
        setup_desktop
    fi

    if should_run "dev"; then
        setup_dev
    fi

    if should_run "editors"; then
        setup_editors
    fi

    if should_run "security"; then
        setup_security
    fi

    if should_run "gaming"; then
        setup_gaming
    fi

    if should_run "content"; then
        setup_content
    fi

    # ── Summary ───────────────────────────────────────────────────────────────
    _print_summary
}

# ── Final Summary ─────────────────────────────────────────────────────────────
_print_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}"
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║            ✅  SETUP COMPLETE                                ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"

    log_section "Next Steps"

    echo -e "${CYAN}1. REBOOT NOW${RESET} — many changes (GPU drivers, groups, kernel modules) need it:"
    echo "   sudo reboot"
    echo ""
    echo -e "${CYAN}2. After reboot — Hyprland will start via greetd/tuigreet.${RESET}"
    echo "   If it doesn't launch, check: journalctl -xe | grep hyprland"
    echo ""
    echo -e "${CYAN}3. SSH Key — add your public key to GitHub/GitLab:${RESET}"
    echo "   cat ~/.ssh/id_ed25519.pub"
    echo "   gh auth login   (to authenticate GitHub CLI)"
    echo ""
    echo -e "${CYAN}4. Tailscale — authenticate to your network:${RESET}"
    echo "   sudo tailscale up"
    echo ""
    echo -e "${CYAN}5. Docker — re-login for group membership to take effect:${RESET}"
    echo "   (reboot handles this)"
    echo ""
    echo -e "${CYAN}6. Android Studio — open JetBrains Toolbox to install:${RESET}"
    echo "   ~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox"
    echo ""
    echo -e "${CYAN}7. Kali Linux VM — open virt-manager to complete installation:${RESET}"
    echo "   virt-manager"
    echo "   (or: virsh start kali-linux)"
    echo ""
    echo -e "${CYAN}8. Neovim — plugins install on first launch automatically:${RESET}"
    echo "   nvim   (wait ~1 minute on first run)"
    echo ""
    echo -e "${CYAN}9. Zed — open any project to trigger LSP downloads:${RESET}"
    echo "   zed ."
    echo ""
    echo -e "${CYAN}10. Flutter — run flutter doctor to see remaining setup:${RESET}"
    echo "    flutter doctor"
    echo ""
    echo -e "${CYAN}11. ML/Python — create a project with uv:${RESET}"
    echo "    uv init my-ml-project && cd my-ml-project"
    echo "    uv add numpy pandas torch"
    echo ""
    echo -e "${BOLD}Full install log saved to: $LOG_FILE${RESET}"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}════════════════════════════════════════${RESET}"
        echo -e "${YELLOW}  DRY RUN COMPLETE — nothing was changed${RESET}"
        echo -e "${YELLOW}════════════════════════════════════════${RESET}"
    fi
}

# ── Entry point ───────────────────────────────────────────────────────────────
main "$@"
