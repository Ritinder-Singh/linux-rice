local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("CaskaydiaCove Nerd Font", { weight = "Regular" })
config.font_size = 14.0
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 10000

config.keys = {
  { key = "d", mods = "CMD",       action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "D", mods = "CMD|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "w", mods = "CMD",       action = wezterm.action.CloseCurrentPane({ confirm = false }) },
  { key = "h", mods = "CMD|ALT",   action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "l", mods = "CMD|ALT",   action = wezterm.action.ActivatePaneDirection("Right") },
  { key = "k", mods = "CMD|ALT",   action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "j", mods = "CMD|ALT",   action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "t", mods = "CMD",       action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "[", mods = "CMD",       action = wezterm.action.ActivateTabRelative(-1) },
  { key = "]", mods = "CMD",       action = wezterm.action.ActivateTabRelative(1) },
}

return config
