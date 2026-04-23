#!/usr/bin/env bash
# Rofi wallpaper picker — select a wallpaper and apply Matugen theming

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
mkdir -p "$WALLPAPER_DIR"

SELECTED=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) \
  | rofi -dmenu -p " Wallpaper" -show-icons)

if [[ -n "$SELECTED" ]]; then
    swww img "$SELECTED" \
        --transition-type wipe \
        --transition-angle 30 \
        --transition-duration 1.5

    # Save current wallpaper path
    echo "$SELECTED" > "$HOME/.config/current-wallpaper"

    # Regenerate colors with Matugen
    matugen image "$SELECTED"
fi
