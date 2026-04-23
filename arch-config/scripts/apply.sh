#!/usr/bin/env bash
# Pulls latest changes and applies all dotfiles to $HOME

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Pulling latest..."
git -C "$DOTFILES_DIR" pull

echo "Applying dotfiles..."

# .config entries
for dir in "$DOTFILES_DIR"/.config/*/; do
    name=$(basename "$dir")
    mkdir -p "$HOME/.config/$name"
    cp -r "$dir"* "$HOME/.config/$name/" 2>/dev/null || true
done

# Shell & git files
cp "$DOTFILES_DIR"/.zshrc            "$HOME/.zshrc"
cp "$DOTFILES_DIR"/.zshenv           "$HOME/.zshenv"
cp "$DOTFILES_DIR"/.gitconfig        "$HOME/.gitconfig"
cp "$DOTFILES_DIR"/.gitignore_global "$HOME/.gitignore_global"

# Scripts executable
chmod +x "$HOME/.config/hypr/scripts/wallpaper-picker.sh"
chmod +x "$HOME/.config/hypr/scripts/toggle-theme.sh"

echo "Done. Reload Hyprland with SUPER+SHIFT+R"
