# ── Session variables — loaded for all zsh sessions ───────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="kitty"
export BROWSER="zen"

# ── XDG ───────────────────────────────────────────────────────────────────────
export XDG_CURRENT_DESKTOP="Hyprland"
export XDG_SESSION_TYPE="wayland"
export XDG_SESSION_DESKTOP="Hyprland"

# ── NVIDIA Wayland ────────────────────────────────────────────────────────────
export LIBVA_DRIVER_NAME="nvidia"
export GBM_BACKEND="nvidia-drm"
export __GLX_VENDOR_LIBRARY_NAME="nvidia"
export WLR_NO_HARDWARE_CURSORS="1"

# ── Dev paths ─────────────────────────────────────────────────────────────────
export GOPATH="$HOME/go"
export CARGO_HOME="$HOME/.cargo"
export PATH="$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin:$PATH"
