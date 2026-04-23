#!/usr/bin/env bash
# Toggle between Matugen dark and light variants

THEME_FILE="$HOME/.config/theme-variant"
WALLPAPER=$(cat "$HOME/.config/current-wallpaper" 2>/dev/null)

if [[ ! -f "$THEME_FILE" ]] || [[ "$(cat $THEME_FILE)" == "dark" ]]; then
    echo "light" > "$THEME_FILE"
    [[ -n "$WALLPAPER" ]] && matugen image "$WALLPAPER" --type scheme-content --mode light
else
    echo "dark" > "$THEME_FILE"
    [[ -n "$WALLPAPER" ]] && matugen image "$WALLPAPER" --type scheme-content --mode dark
fi

# Reload Waybar
pkill -SIGUSR2 waybar
