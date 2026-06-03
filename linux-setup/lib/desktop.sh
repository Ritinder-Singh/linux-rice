#!/usr/bin/env bash
# =============================================================================
# lib/desktop.sh — Hyprland + full WM stack
# Covers: Hyprland, Waybar, Rofi, swww, Matugen, Hyprshot, Yazi, Ghostty,
#         Zellij, btm, PipeWire audio
# =============================================================================

setup_desktop() {
    _install_hyprland_deps
    _install_hyprland
    _install_wm_stack
    _install_ghostty
    _install_zellij
    _install_btm
    _write_hyprland_config
    _write_waybar_config
    _write_rofi_config
    _write_hyprshot_config
    _setup_yazi
    _setup_pipewire_audio
    _setup_display_manager
}

# ── Hyprland Dependencies ─────────────────────────────────────────────────────
_install_hyprland_deps() {
    log_section "Hyprland Dependencies"

    apt_install \
        libwayland-dev \
        libxkbcommon-dev \
        libpixman-1-dev \
        libegl-dev \
        libgles2-mesa-dev \
        libdrm-dev \
        libgbm-dev \
        libudev-dev \
        libseat-dev \
        libxcb-util-dev \
        libxcb-icccm4-dev \
        libxcb-image0-dev \
        libxcb-keysyms1-dev \
        libxcb-randr0-dev \
        libxcb-render-util0-dev \
        libxcb-xinerama0-dev \
        libxcb-xkb-dev \
        libxcb-shape0-dev \
        xwayland \
        libx11-xcb-dev \
        libxcb-dri3-dev \
        libxcb-present-dev \
        polkit-gnome \
        xdg-desktop-portal-hyprland \
        xdg-desktop-portal-gtk \
        qt5-gtk-platformtheme \
        qt6-wayland \
        libnotify-bin \
        notification-daemon \
        libglib2.0-dev \
        libpango1.0-dev \
        libcairo2-dev \
        libgdk-pixbuf-2.0-dev \
        libatk1.0-dev \
        grim \
        slurp \
        wl-clipboard \
        cliphist \
        brightnessctl \
        playerctl \
        pavucontrol \
        network-manager \
        network-manager-gnome \
        blueman \
        bluez

    log_ok "Hyprland dependencies installed."
}

# ── Hyprland (via official PPA) ────────────────────────────────────────────────
_install_hyprland() {
    log_section "Hyprland"

    if ! has_cmd hyprland; then
        log_step "Adding Hyprland PPA (hyprland-unofficial/hyprland)..."
        run sudo add-apt-repository -y ppa:hyprland-unofficial/hyprland
        run sudo apt-get update
        apt_install hyprland
    else
        log_info "Hyprland already installed."
    fi

    log_ok "Hyprland installed."
}

# ── WM Stack: Waybar, Rofi, swww, Matugen, Hyprshot ─────────────────────────
_install_wm_stack() {
    log_section "WM Stack (Waybar, Rofi, swww, Matugen, Hyprshot)"

    # Waybar
    if ! has_cmd waybar; then
        log_step "Installing Waybar..."
        apt_install waybar
    fi

    # Rofi-wayland
    if ! has_cmd rofi; then
        log_step "Installing Rofi (Wayland fork)..."
        apt_install rofi-wayland 2>/dev/null || apt_install rofi
    fi

    # swww (wallpaper daemon) — install from GitHub releases
    if ! has_cmd swww; then
        log_step "Installing swww (wallpaper daemon)..."
        local swww_version
        swww_version=$(curl -fsSL "https://api.github.com/repos/LGFae/swww/releases/latest" | jq -r '.tag_name')
        download "https://github.com/LGFae/swww/releases/download/${swww_version}/swww-${swww_version}-x86_64-unknown-linux-musl.tar.gz" \
            /tmp/swww.tar.gz
        run tar -xzf /tmp/swww.tar.gz -C /tmp/
        run sudo install -m 755 /tmp/swww /usr/local/bin/swww
        run sudo install -m 755 /tmp/swww-daemon /usr/local/bin/swww-daemon
        run rm -f /tmp/swww.tar.gz /tmp/swww /tmp/swww-daemon
    fi

    # Matugen (wallpaper-driven theming) — via cargo
    if ! has_cmd matugen; then
        log_step "Installing Matugen (theming engine)..."
        if has_cmd cargo; then
            run cargo install matugen
        else
            log_warn "Rust/Cargo not yet installed. Matugen will be installed after Rust setup."
            # Flag for post-rust install
            touch /tmp/.install_matugen_later
        fi
    fi

    # Hyprshot (screenshot tool)
    if ! has_cmd hyprshot; then
        log_step "Installing Hyprshot..."
        local hs_version
        hs_version=$(curl -fsSL "https://api.github.com/repos/Gustash/Hyprshot/releases/latest" | jq -r '.tag_name')
        download "https://github.com/Gustash/Hyprshot/releases/download/${hs_version}/hyprshot" \
            /tmp/hyprshot
        run sudo install -m 755 /tmp/hyprshot /usr/local/bin/hyprshot
        run rm -f /tmp/hyprshot
    fi

    # dunst (notification daemon)
    apt_install dunst libnotify-bin

    log_ok "WM stack installed."
}

# ── Ghostty Terminal ───────────────────────────────────────────────────────────
_install_ghostty() {
    log_section "Ghostty Terminal"

    if ! has_cmd ghostty; then
        log_step "Installing Ghostty via snap (official distribution)..."
        run sudo snap install ghostty --classic 2>/dev/null || {
            log_warn "Snap install failed. Trying AppImage fallback..."
            local ghostty_ver
            ghostty_ver=$(curl -fsSL "https://api.github.com/repos/ghostty-org/ghostty/releases/latest" | jq -r '.tag_name')
            download "https://github.com/ghostty-org/ghostty/releases/download/${ghostty_ver}/Ghostty-${ghostty_ver}.AppImage" \
                "$HOME/.local/bin/ghostty"
            run chmod +x "$HOME/.local/bin/ghostty"
        }
    else
        log_info "Ghostty already installed."
    fi

    # Ghostty config
    mkdir -p "$HOME/.config/ghostty"
    cat > "$HOME/.config/ghostty/config" <<'GHOSTTY'
font-family = "JetBrainsMono Nerd Font"
font-size = 13
theme = catppuccin-mocha
cursor-style = bar
cursor-style-blink = true
window-padding-x = 12
window-padding-y = 10
background-opacity = 0.92
background-blur-radius = 20
scrollback-limit = 10000
shell-integration = zsh
window-decoration = false
GHOSTTY

    log_ok "Ghostty installed and configured."
}

# ── Zellij ────────────────────────────────────────────────────────────────────
_install_zellij() {
    log_section "Zellij (Terminal Multiplexer)"

    if ! has_cmd zellij; then
        log_step "Installing Zellij..."
        local zj_version
        zj_version=$(curl -fsSL "https://api.github.com/repos/zellij-org/zellij/releases/latest" | jq -r '.tag_name')
        download "https://github.com/zellij-org/zellij/releases/download/${zj_version}/zellij-x86_64-unknown-linux-musl.tar.gz" \
            /tmp/zellij.tar.gz
        run tar -xzf /tmp/zellij.tar.gz -C /tmp/
        run sudo install -m 755 /tmp/zellij /usr/local/bin/zellij
        run rm -f /tmp/zellij.tar.gz /tmp/zellij
    fi

    # Zellij config
    mkdir -p "$HOME/.config/zellij"
    cat > "$HOME/.config/zellij/config.kdl" <<'ZELLIJ'
theme "catppuccin-mocha"
default_shell "zsh"
pane_frames false
auto_layout true
copy_on_select true

keybinds clear-defaults=true {
    normal {
        bind "Ctrl g" { SwitchToMode "Locked"; }
        bind "Ctrl p" { SwitchToMode "Pane"; }
        bind "Ctrl t" { SwitchToMode "Tab"; }
        bind "Ctrl n" { SwitchToMode "Resize"; }
        bind "Ctrl s" { SwitchToMode "Scroll"; }
        bind "Ctrl q" { Quit; }
    }
    locked {
        bind "Ctrl g" { SwitchToMode "Normal"; }
    }
}
ZELLIJ

    log_ok "Zellij installed and configured."
}

# ── btm (bottom — system monitor) ─────────────────────────────────────────────
_install_btm() {
    log_section "btm (System Monitor)"

    if ! has_cmd btm; then
        local btm_version
        btm_version=$(curl -fsSL "https://api.github.com/repos/ClementTsang/bottom/releases/latest" | jq -r '.tag_name')
        download "https://github.com/ClementTsang/bottom/releases/download/${btm_version}/bottom_${btm_version}-1_amd64.deb" \
            /tmp/bottom.deb
        run sudo dpkg -i /tmp/bottom.deb
        run rm -f /tmp/bottom.deb
        log_ok "btm installed."
    else
        log_info "btm already installed."
    fi
}

# ── Yazi (File Manager) ────────────────────────────────────────────────────────
_setup_yazi() {
    log_section "Yazi File Manager"

    if ! has_cmd yazi; then
        log_step "Installing Yazi..."
        local yazi_version
        yazi_version=$(curl -fsSL "https://api.github.com/repos/sxyazi/yazi/releases/latest" | jq -r '.tag_name')
        download "https://github.com/sxyazi/yazi/releases/download/${yazi_version}/yazi-x86_64-unknown-linux-musl.zip" \
            /tmp/yazi.zip
        run unzip -o /tmp/yazi.zip -d /tmp/yazi_extracted/
        run sudo install -m 755 /tmp/yazi_extracted/yazi-x86_64-unknown-linux-musl/yazi /usr/local/bin/yazi
        run rm -rf /tmp/yazi.zip /tmp/yazi_extracted
    fi

    log_ok "Yazi installed."
}

# ── PipeWire Audio ─────────────────────────────────────────────────────────────
_setup_pipewire_audio() {
    log_section "PipeWire Audio"

    apt_install \
        pipewire \
        pipewire-audio \
        pipewire-pulse \
        pipewire-jack \
        wireplumber \
        pavucontrol \
        easyeffects

    # Enable as user service
    run systemctl --user enable pipewire pipewire-pulse wireplumber
    run systemctl --user start pipewire pipewire-pulse wireplumber 2>/dev/null || \
        log_warn "PipeWire services will start on next login."

    log_ok "PipeWire audio configured."
}

# ── Display Manager (SDDM / greetd) ───────────────────────────────────────────
_setup_display_manager() {
    log_section "Display Manager (greetd + tuigreet)"

    apt_install greetd 2>/dev/null || {
        log_warn "greetd not in apt, trying alternative..."
        apt_install lightdm lightdm-gtk-greeter
        run sudo systemctl enable lightdm
        log_ok "LightDM installed as display manager fallback."
        return
    }

    # tuigreet
    local tg_version
    tg_version=$(curl -fsSL "https://api.github.com/repos/apognu/tuigreet/releases/latest" | jq -r '.tag_name')
    download "https://github.com/apognu/tuigreet/releases/download/${tg_version}/tuigreet-${tg_version}-amd64" \
        /tmp/tuigreet
    run sudo install -m 755 /tmp/tuigreet /usr/local/bin/tuigreet
    run rm -f /tmp/tuigreet

    sudo tee /etc/greetd/config.toml > /dev/null <<GREETD
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd Hyprland"
user = "greeter"
GREETD

    run sudo systemctl enable greetd
    log_ok "greetd + tuigreet configured to launch Hyprland."
}

# ── Hyprland Config ────────────────────────────────────────────────────────────
_write_hyprland_config() {
    log_section "Hyprland Configuration"

    local HYPR_DIR="$HOME/.config/hypr"
    mkdir -p "$HYPR_DIR"

    # Source NVIDIA config if it was written by gpu.sh
    local nvidia_source=""
    [[ -f "$HYPR_DIR/env_nvidia.conf" ]] && nvidia_source="source = ~/.config/hypr/env_nvidia.conf"

    cat > "$HYPR_DIR/hyprland.conf" <<HYPRCONF
# =============================================================================
# Hyprland Configuration
# Generated by linux-setup installer
# =============================================================================

# Source NVIDIA env vars if present
$nvidia_source

# ── Monitors ─────────────────────────────────────────────────────────────────
monitor=,preferred,auto,1

# ── Auto-start ────────────────────────────────────────────────────────────────
exec-once = swww-daemon
exec-once = waybar
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = swww img ~/.config/hypr/wallpaper.jpg

# ── Environment ────────────────────────────────────────────────────────────────
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland
env = QT_QPA_PLATFORMTHEME,gtk3
env = MOZ_ENABLE_WAYLAND,1
env = _JAVA_AWT_WM_NONREPARENTING,1
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland

# ── General ───────────────────────────────────────────────────────────────────
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(cba6f7ff) rgba(89b4faff) 45deg
    col.inactive_border = rgba(45475aff)
    layout = dwindle
    allow_tearing = false
}

# ── Decoration ────────────────────────────────────────────────────────────────
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 8
        passes = 2
        new_optimizations = true
        xray = false
    }
    drop_shadow = true
    shadow_range = 12
    shadow_render_power = 3
    col.shadow = rgba(1e1e2eee)
    active_opacity = 1.0
    inactive_opacity = 0.95
}

# ── Animations ────────────────────────────────────────────────────────────────
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# ── Layouts ───────────────────────────────────────────────────────────────────
dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_is_master = true
}

# ── Input ─────────────────────────────────────────────────────────────────────
input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0
    touchpad {
        natural_scroll = true
        disable_while_typing = true
        tap-to-click = true
    }
}

gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}

# ── Misc ──────────────────────────────────────────────────────────────────────
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    mouse_move_enables_dpms = true
    key_press_enables_dpms = true
}

# ── Window Rules ──────────────────────────────────────────────────────────────
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(file-roller)$
windowrulev2 = float, class:^(xdg-desktop-portal)$, title:^(All Files)$

# ── Keybinds ──────────────────────────────────────────────────────────────────
\$mainMod = SUPER

# Applications
bind = \$mainMod, Return, exec, ghostty
bind = \$mainMod, E, exec, ghostty -e yazi
bind = \$mainMod, B, exec, zen-browser
bind = \$mainMod SHIFT, B, exec, firefox
bind = \$mainMod, C, killactive,
bind = \$mainMod SHIFT, E, exit,
bind = \$mainMod, Space, exec, rofi -show drun
bind = \$mainMod, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy

# Screenshots (hyprshot)
bind = , Print, exec, hyprshot -m output
bind = \$mainMod, Print, exec, hyprshot -m region
bind = \$mainMod SHIFT, Print, exec, hyprshot -m window

# Window management
bind = \$mainMod, F, fullscreen, 0
bind = \$mainMod SHIFT, F, fullscreen, 1
bind = \$mainMod, P, pseudo,
bind = \$mainMod, J, togglesplit,
bind = \$mainMod, T, togglefloating,

# Move focus
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d
bind = \$mainMod, H, movefocus, l
bind = \$mainMod, L, movefocus, r
bind = \$mainMod, K, movefocus, u
bind = \$mainMod, J, movefocus, d

# Move windows
bind = \$mainMod SHIFT, left, movewindow, l
bind = \$mainMod SHIFT, right, movewindow, r
bind = \$mainMod SHIFT, up, movewindow, u
bind = \$mainMod SHIFT, down, movewindow, d

# Resize windows
binde = \$mainMod ALT, right, resizeactive, 30 0
binde = \$mainMod ALT, left, resizeactive, -30 0
binde = \$mainMod ALT, up, resizeactive, 0 -30
binde = \$mainMod ALT, down, resizeactive, 0 30

# Workspaces
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod, 4, workspace, 4
bind = \$mainMod, 5, workspace, 5
bind = \$mainMod, 6, workspace, 6
bind = \$mainMod, 7, workspace, 7
bind = \$mainMod, 8, workspace, 8
bind = \$mainMod, 9, workspace, 9
bind = \$mainMod, 0, workspace, 10

bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3
bind = \$mainMod SHIFT, 4, movetoworkspace, 4
bind = \$mainMod SHIFT, 5, movetoworkspace, 5
bind = \$mainMod SHIFT, 6, movetoworkspace, 6
bind = \$mainMod SHIFT, 7, movetoworkspace, 7
bind = \$mainMod SHIFT, 8, movetoworkspace, 8
bind = \$mainMod SHIFT, 9, movetoworkspace, 9
bind = \$mainMod SHIFT, 0, movetoworkspace, 10

# Scroll workspaces
bind = \$mainMod, mouse_down, workspace, e+1
bind = \$mainMod, mouse_up, workspace, e-1

# Move/resize with mouse
bindm = \$mainMod, mouse:272, movewindow
bindm = \$mainMod, mouse:273, resizewindow

# Media keys
binde = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind  = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bind  = , XF86AudioPlay, exec, playerctl play-pause
bind  = , XF86AudioNext, exec, playerctl next
bind  = , XF86AudioPrev, exec, playerctl previous
binde = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
binde = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Lock screen
bind = \$mainMod, Escape, exec, hyprlock
HYPRCONF

    # Download a default Catppuccin Mocha wallpaper
    log_step "Downloading default wallpaper..."
    download "https://raw.githubusercontent.com/catppuccin/wallpapers/main/minimalistic/cat-sound.png" \
        "$HYPR_DIR/wallpaper.jpg" 2>/dev/null || \
        log_warn "Could not download default wallpaper. Add one manually to ~/.config/hypr/wallpaper.jpg"

    # hyprlock config
    cat > "$HYPR_DIR/hyprlock.conf" <<'HYPRLOCK'
background {
    monitor =
    path = ~/.config/hypr/wallpaper.jpg
    blur_passes = 3
    blur_size = 8
}

input-field {
    monitor =
    size = 300, 50
    outline_thickness = 3
    dots_size = 0.26
    dots_spacing = 0.64
    dots_center = true
    outer_color = rgb(cba6f7)
    inner_color = rgb(1e1e2e)
    font_color = rgb(cdd6f4)
    fade_on_empty = true
    placeholder_text = Password
    hide_input = false
    position = 0, -80
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:1000] echo "<b>$(date +"%H:%M")</b>"
    color = rgba(cdd6f4ff)
    font_size = 64
    font_family = JetBrainsMono Nerd Font
    position = 0, 80
    halign = center
    valign = center
}
HYPRLOCK

    apt_install hyprlock 2>/dev/null || log_warn "hyprlock not found in apt — install manually if needed."

    log_ok "Hyprland config written to ~/.config/hypr/"
}

# ── Waybar Config ─────────────────────────────────────────────────────────────
_write_waybar_config() {
    log_section "Waybar Configuration"

    local WAYBAR_DIR="$HOME/.config/waybar"
    mkdir -p "$WAYBAR_DIR"

    cat > "$WAYBAR_DIR/config.jsonc" <<'WAYBAR_CFG'
{
    "layer": "top",
    "position": "top",
    "height": 34,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces", "hyprland/submap", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": [
        "pulseaudio",
        "network",
        "bluetooth",
        "cpu",
        "memory",
        "temperature",
        "battery",
        "tray",
        "custom/power"
    ],

    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "󰲡",
            "2": "󰲣",
            "3": "󰲥",
            "4": "󰲧",
            "5": "󰲩",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },

    "hyprland/window": {
        "max-length": 50,
        "separate-outputs": true
    },

    "clock": {
        "format": " {:%H:%M}",
        "format-alt": " {:%A, %B %d, %Y}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "interval": 1
    },

    "cpu": {
        "format": "󰍛 {usage}%",
        "tooltip": false,
        "interval": 2
    },

    "memory": {
        "format": " {used:0.1f}G/{total:0.1f}G",
        "interval": 2
    },

    "temperature": {
        "critical-threshold": 80,
        "format": "{icon} {temperatureC}°C",
        "format-icons": ["", "", ""]
    },

    "battery": {
        "states": {
            "good": 95,
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": "󰂄 {capacity}%",
        "format-plugged": "󰚥 {capacity}%",
        "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },

    "network": {
        "format-wifi": "󰤨 {signalStrength}%",
        "format-ethernet": "󰈀 Connected",
        "format-disconnected": "󰤭 Disconnected",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}\n{essid}",
        "on-click": "nm-connection-editor"
    },

    "bluetooth": {
        "format": "󰂯 {status}",
        "format-connected": "󰂱 {device_alias}",
        "format-connected-battery": "󰂱 {device_alias} ({device_battery_percentage}%)",
        "on-click": "blueman-manager"
    },

    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-bluetooth": "{icon} {volume}%",
        "format-muted": "󰝟",
        "format-icons": {
            "headphone": "󰋋",
            "default": ["󰕿", "󰖀", "󰕾"]
        },
        "on-click": "pavucontrol"
    },

    "tray": {
        "spacing": 8
    },

    "custom/power": {
        "format": "󰐥",
        "on-click": "rofi -show power-menu -modi power-menu:~/.config/rofi/scripts/rofi-power-menu",
        "tooltip": false
    }
}
WAYBAR_CFG

    cat > "$WAYBAR_DIR/style.css" <<'WAYBAR_CSS'
/* Catppuccin Mocha Waybar Theme */
* {
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
    border: none;
    border-radius: 0;
    min-height: 0;
}

window#waybar {
    background-color: rgba(30, 30, 46, 0.9);
    color: #cdd6f4;
    transition-property: background-color;
    transition-duration: 0.5s;
    border-bottom: 2px solid rgba(203, 166, 247, 0.4);
}

.modules-left,
.modules-right,
.modules-center {
    margin: 3px 6px;
}

#workspaces button {
    padding: 0 6px;
    background-color: transparent;
    color: #6c7086;
    border-bottom: 3px solid transparent;
}

#workspaces button.active {
    color: #cba6f7;
    border-bottom: 3px solid #cba6f7;
}

#workspaces button.urgent {
    color: #f38ba8;
    border-bottom: 3px solid #f38ba8;
}

#workspaces button:hover {
    background: rgba(203, 166, 247, 0.1);
}

#clock { color: #89b4fa; font-weight: bold; }
#cpu { color: #a6e3a1; }
#memory { color: #fab387; }
#temperature { color: #f38ba8; }
#battery { color: #a6e3a1; }
#battery.warning { color: #f9e2af; }
#battery.critical { color: #f38ba8; }
#battery.charging { color: #a6e3a1; }
#network { color: #89dceb; }
#pulseaudio { color: #cba6f7; }
#bluetooth { color: #89b4fa; }
#tray { color: #cdd6f4; }
#window { color: #cdd6f4; font-style: italic; }
#custom-power { color: #f38ba8; font-size: 16px; margin-right: 6px; }
WAYBAR_CSS

    log_ok "Waybar config written."
}

# ── Rofi Config ───────────────────────────────────────────────────────────────
_write_rofi_config() {
    log_section "Rofi Configuration"

    local ROFI_DIR="$HOME/.config/rofi"
    mkdir -p "$ROFI_DIR/scripts"

    cat > "$ROFI_DIR/config.rasi" <<'ROFI_CFG'
configuration {
    modi: "drun,run,window,ssh";
    show-icons: true;
    drun-display-format: "{name}";
    window-format: "{w} · {c} · {t}";
    display-drun: "Apps";
    display-run: "Run";
    display-window: "Windows";
    kb-primary-paste: "Control+V";
    kb-secondary-paste: "Control+v";
}

@theme "catppuccin-mocha"
ROFI_CFG

    # Write Catppuccin Mocha theme for Rofi
    mkdir -p "$ROFI_DIR/themes"
    cat > "$ROFI_DIR/themes/catppuccin-mocha.rasi" <<'ROFI_THEME'
* {
    bg: #1e1e2e;
    bg-alt: #181825;
    bg-selected: #313244;
    fg: #cdd6f4;
    fg-alt: #6c7086;
    accent: #cba6f7;
    urgent: #f38ba8;
    border-color: #cba6f7;
    border-radius: 10px;
    font: "JetBrainsMono Nerd Font 12";
}

window {
    background-color: @bg;
    border: 2px;
    border-color: @border-color;
    border-radius: @border-radius;
    width: 500px;
}

mainbox { background-color: transparent; children: [inputbar, listview]; }

inputbar {
    background-color: @bg-alt;
    border-radius: @border-radius @border-radius 0 0;
    padding: 10px;
    children: [prompt, entry];
}

prompt { color: @accent; }

entry {
    color: @fg;
    background-color: transparent;
    placeholder-color: @fg-alt;
}

listview {
    background-color: transparent;
    padding: 6px;
    lines: 8;
}

element {
    background-color: transparent;
    padding: 6px 8px;
    border-radius: 6px;
}

element selected { background-color: @bg-selected; }
element-text { color: @fg; vertical-align: 0.5; }
element-icon { size: 24px; }
ROFI_THEME

    # Symlink the theme
    ln -sf "$ROFI_DIR/themes/catppuccin-mocha.rasi" "$ROFI_DIR/catppuccin-mocha.rasi"

    # Power menu script
    cat > "$ROFI_DIR/scripts/rofi-power-menu" <<'POWER_MENU'
#!/usr/bin/env bash
declare -A items=(
    ["Shutdown"]="systemctl poweroff"
    ["Reboot"]="systemctl reboot"
    ["Suspend"]="systemctl suspend"
    ["Lock"]="hyprlock"
    ["Logout"]="hyprctl dispatch exit"
)
declare -a order=("Lock" "Suspend" "Logout" "Reboot" "Shutdown")

if [[ -z "$@" ]]; then
    for item in "${order[@]}"; do echo "$item"; done
else
    ${items[$@]}
fi
POWER_MENU
    chmod +x "$ROFI_DIR/scripts/rofi-power-menu"

    log_ok "Rofi configured with Catppuccin Mocha theme."
}

# ── Hyprshot Config ───────────────────────────────────────────────────────────
_write_hyprshot_config() {
    mkdir -p "$HOME/Pictures/Screenshots"
    # Hyprshot stores screenshots here by default
    log_ok "Screenshot directory: ~/Pictures/Screenshots"
}
