#!/bin/zsh
# Pulls latest changes and re-applies all dotfiles to $HOME

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Pulling latest..."
git -C "$DOTFILES_DIR" pull

echo "Applying dotfiles..."

for dir in "$DOTFILES_DIR"/.config/*/; do
  name=$(basename "$dir")
  mkdir -p "$HOME/.config/$name"
  cp -r "$dir"* "$HOME/.config/$name/"
done

cp "$DOTFILES_DIR"/.zshrc            "$HOME/.zshrc"
cp "$DOTFILES_DIR"/.gitconfig        "$HOME/.gitconfig"
cp "$DOTFILES_DIR"/.gitignore_global "$HOME/.gitignore_global"

echo "Done. Restart your terminal or run: source ~/.zshrc"
