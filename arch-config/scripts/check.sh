#!/usr/bin/env bash
# ── Post-install check — verifies all tools are available ─────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
MISSING=()

check() {
    local name="$1"
    local cmd="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $name"
        ((PASS++))
    else
        echo -e "  ${RED}✗${NC} $name"
        ((FAIL++))
        MISSING+=("$name")
    fi
}

echo ""
echo "── Hyprland stack ───────────────────────────────────────────────────────"
check "hyprland"
check "hyprlock"
check "hypridle"
check "waybar"
check "rofi"
check "swww"
check "swayosd-client"
check "swaync"
check "hyprshot"
check "wl-copy" "wl-copy"
check "notify-send"
check "matugen"
check "brightnessctl"

echo ""
echo "── Terminal & shell ─────────────────────────────────────────────────────"
check "kitty"
check "zellij"
check "zsh"
check "starship"
check "fastfetch"
check "figlet"
check "cava"

echo ""
echo "── CLI tools ────────────────────────────────────────────────────────────"
check "eza"
check "bat"
check "zoxide"
check "lazygit"
check "fzf"
check "ripgrep" "rg"
check "fd"
check "jq"
check "yq"
check "delta"
check "direnv"
check "shellcheck"
check "shfmt"
check "yazi"
check "btm"
check "ngrok"

echo ""
echo "── Editors ──────────────────────────────────────────────────────────────"
check "neovim" "nvim"
check "code" "codium"

echo ""
echo "── Media & audio ────────────────────────────────────────────────────────"
check "playerctl"
check "pipewire"
check "pavucontrol"
check "mpv"
check "imv"

echo ""
echo "── Bluetooth ────────────────────────────────────────────────────────────"
check "blueman-manager"
check "bluetoothctl"

echo ""
echo "── Dev languages ────────────────────────────────────────────────────────"
check "node"
check "python"
check "go"
check "rustup"
check "zig"
check "ruby"
check "ocaml"
check "java"
check "kotlin"
check "gradle"
check "clang"
check "cmake"

echo ""
echo "── Version managers ─────────────────────────────────────────────────────"
check "fnm"
check "uv"
check "rustup"

echo ""
echo "── DevOps ───────────────────────────────────────────────────────────────"
check "kubectl"
check "helm"
check "k9s"
check "podman"
check "opentofu" "tofu"
check "terragrunt"

echo ""
echo "── Git & GitHub ─────────────────────────────────────────────────────────"
check "git"
check "gh"
check "git-lfs" "git-lfs"

echo ""
echo "── Apps ─────────────────────────────────────────────────────────────────"
check "keepassxc"
check "obsidian"
check "chromium"
check "zen" "zen"
check "thunar"

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
echo -e "  ${GREEN}Passed: $PASS${NC}  ${RED}Failed: $FAIL${NC}"

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${YELLOW}Missing — install with:${NC}"
    echo "  paru -S ${MISSING[*]}"
fi

echo ""
