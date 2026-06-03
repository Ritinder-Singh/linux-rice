#!/usr/bin/env bash
# =============================================================================
# lib/editors.sh — Editors & IDEs
# Covers: Neovim + LazyVim, Zed (with full IDE config), Android Studio
# =============================================================================

setup_editors() {
    _install_neovim
    _install_zed
    _install_android_studio
}

# ── Neovim + LazyVim ──────────────────────────────────────────────────────────
_install_neovim() {
    log_section "Neovim + LazyVim"

    # Install latest stable Neovim from GitHub releases
    if ! has_cmd nvim; then
        log_step "Installing Neovim (latest stable)..."
        local nvim_version
        nvim_version=$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" | jq -r '.tag_name')
        download "https://github.com/neovim/neovim/releases/download/${nvim_version}/nvim-linux64.tar.gz" \
            /tmp/nvim.tar.gz
        run sudo tar -xzf /tmp/nvim.tar.gz -C /opt/
        run sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
        run rm -f /tmp/nvim.tar.gz
    else
        log_info "Neovim already installed: $(nvim --version | head -1)"
    fi

    # Neovim dependencies
    apt_install \
        lua5.1 \
        luarocks \
        python3-pynvim \
        xclip \
        xsel

    # Install LazyVim starter config
    local NVIM_CONFIG="$HOME/.config/nvim"
    if [[ ! -d "$NVIM_CONFIG" ]]; then
        log_step "Installing LazyVim starter config..."
        run git clone --depth=1 https://github.com/LazyVim/starter "$NVIM_CONFIG"
        run rm -rf "$NVIM_CONFIG/.git"
    else
        log_info "Neovim config already exists at $NVIM_CONFIG — not overwriting."
    fi

    # Write a minimal custom LazyVim config on top of starter
    mkdir -p "$NVIM_CONFIG/lua/plugins"

    cat > "$NVIM_CONFIG/lua/plugins/custom.lua" <<'NVIM_PLUGINS'
-- Custom plugins on top of LazyVim
return {
  -- Catppuccin Mocha theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        telescope = { enabled = true },
        which_key = true,
      },
    },
  },

  -- Set Catppuccin as the colorscheme
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },

  -- Harpoon (fast file navigation)
  { "ThePrimeagen/harpoon", branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon Add" },
      { "<leader>hh", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon Menu" },
    },
  },

  -- Flutter tools
  { "akinsho/flutter-tools.nvim", dependencies = { "nvim-lua/plenary.nvim" },
    ft = { "dart" },
    opts = {
      flutter_path = vim.fn.expand("~/.flutter/bin/flutter"),
      lsp = { color = { enabled = true } },
    },
  },

  -- Go tools
  { "ray-x/go.nvim", dependencies = { "ray-x/guihua.lua" }, ft = { "go" }, opts = {} },

  -- Rust tools
  { "simrat39/rust-tools.nvim", ft = "rust" },

  -- Terraform
  { "hashivim/vim-terraform", ft = { "terraform", "tf" } },

  -- Ansible
  { "pearofducks/ansible-vim" },

  -- HTTP client (like httpie in nvim)
  { "rest-nvim/rest.nvim", ft = "http" },

  -- Markdown preview
  { "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    build = "cd app && npm install",
  },
}
NVIM_PLUGINS

    cat > "$NVIM_CONFIG/lua/config/options.lua" <<'NVIM_OPTIONS'
-- Options (extends LazyVim defaults)
local opt = vim.opt

opt.relativenumber = true
opt.number = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.wrap = false
opt.swapfile = false
opt.backup = false
opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
opt.undofile = true
opt.hlsearch = false
opt.incsearch = true
opt.termguicolors = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.isfname:append("@-@")
opt.updatetime = 50
opt.colorcolumn = "100"
opt.clipboard = "unnamedplus"
opt.cursorline = true
opt.splitbelow = true
opt.splitright = true
opt.pumheight = 10
opt.conceallevel = 0
opt.showmode = false
NVIM_OPTIONS

    log_ok "Neovim + LazyVim configured."
    log_info "On first launch, Neovim will auto-install all plugins (needs internet)."
}

# ── Zed Editor ────────────────────────────────────────────────────────────────
_install_zed() {
    log_section "Zed Editor (IDE setup)"

    if ! has_cmd zed; then
        log_step "Installing Zed..."
        run curl -fsSL https://zed.dev/install.sh | sh
    else
        log_info "Zed already installed."
    fi

    # Zed config directory
    local ZED_CONFIG="$HOME/.config/zed"
    mkdir -p "$ZED_CONFIG"

    # Full IDE settings.json
    cat > "$ZED_CONFIG/settings.json" <<'ZED_SETTINGS'
{
  "theme": {
    "mode": "dark",
    "light": "One Light",
    "dark": "Catppuccin Mocha"
  },

  "vim_mode": true,
  "default_dock_anchor": "right",
  "restore_on_startup": "last_workspace",
  "autosave": "on_focus_change",
  "format_on_save": "on",
  "auto_update": true,
  "confirm_quit": false,

  "ui_font_size": 15,
  "buffer_font_family": "JetBrainsMono Nerd Font",
  "buffer_font_size": 14,
  "buffer_line_height": { "custom": 1.6 },

  "tab_size": 2,
  "soft_wrap": "preferred_line_length",
  "preferred_line_length": 100,
  "show_whitespaces": "selection",
  "show_wrap_guides": true,
  "wrap_guides": [100],

  "relative_line_numbers": true,
  "cursor_blink": true,
  "scrollbar": { "show": "auto" },
  "minimap": { "show": "always", "thumb": "always" },
  "indent_guides": { "enabled": true, "coloring": "indent_aware" },
  "inlay_hints": { "enabled": true, "show_type_hints": true, "show_parameter_hints": true },
  "show_completions_on_input": true,
  "use_autoclose": true,
  "show_inline_completions": true,

  "terminal": {
    "font_family": "JetBrainsMono Nerd Font",
    "font_size": 13,
    "line_height": { "custom": 1.5 },
    "shell": { "program": "zsh" },
    "working_directory": "current_project_directory",
    "copy_on_select": true,
    "env": {
      "TERM": "xterm-256color"
    }
  },

  "git": {
    "enabled": true,
    "git_gutter": "tracked_files",
    "inline_blame": { "enabled": true, "delay_ms": 600 }
  },

  "diagnostics": {
    "include_warnings": true
  },

  "file_scan_exclusions": [
    "**/.git",
    "**/.svn",
    "**/node_modules",
    "**/.next",
    "**/dist",
    "**/build",
    "**/__pycache__",
    "**/.mypy_cache",
    "**/.pytest_cache",
    "**/target",
    "**/.terraform",
    "**/.idea",
    "**/.DS_Store"
  ],

  "languages": {
    "TypeScript": {
      "tab_size": 2,
      "formatter": { "external": { "command": "prettier", "arguments": ["--stdin-filepath", "{buffer_path}"] } },
      "format_on_save": "on"
    },
    "JavaScript": {
      "tab_size": 2,
      "formatter": { "external": { "command": "prettier", "arguments": ["--stdin-filepath", "{buffer_path}"] } }
    },
    "Python": {
      "tab_size": 4,
      "formatter": { "language_server": { "name": "ruff" } }
    },
    "Go": {
      "tab_size": 4,
      "formatter": { "language_server": { "name": "gopls" } }
    },
    "Rust": {
      "tab_size": 4,
      "formatter": { "language_server": { "name": "rust-analyzer" } }
    },
    "Dart": {
      "tab_size": 2,
      "formatter": { "language_server": { "name": "dart" } }
    },
    "JSON": {
      "tab_size": 2,
      "formatter": { "external": { "command": "prettier", "arguments": ["--stdin-filepath", "{buffer_path}"] } }
    },
    "Markdown": {
      "soft_wrap": "preferred_line_length",
      "formatter": { "external": { "command": "prettier", "arguments": ["--stdin-filepath", "{buffer_path}"] } }
    },
    "YAML": {
      "tab_size": 2
    },
    "Terraform": {
      "tab_size": 2
    },
    "Dockerfile": {
      "tab_size": 2
    }
  },

  "lsp": {
    "rust-analyzer": {
      "initialization_options": {
        "checkOnSave": { "command": "clippy" },
        "inlayHints": { "parameterHints": { "enable": true }, "typeHints": { "enable": true } }
      }
    },
    "gopls": {
      "initialization_options": {
        "hints": {
          "assignVariableTypes": true,
          "compositeLiteralFields": true,
          "functionTypeParameters": true,
          "parameterNames": true,
          "rangeVariableTypes": true
        }
      }
    },
    "pyright": {
      "initialization_options": {
        "python.analysis": {
          "typeCheckingMode": "basic",
          "autoImportCompletions": true
        }
      }
    }
  },

  "assistant": {
    "enabled": true,
    "version": "2",
    "default_model": {
      "provider": "anthropic",
      "model": "claude-sonnet-4-5"
    }
  },

  "vim": {
    "use_system_clipboard": "always"
  },

  "project_panel": {
    "dock": "left",
    "default_width": 240,
    "file_icons": true,
    "folder_icons": true
  },

  "outline_panel": {
    "dock": "right"
  },

  "collaboration_panel": {
    "dock": "left"
  }
}
ZED_SETTINGS

    # Zed keymap — Vim-style extras
    cat > "$ZED_CONFIG/keymap.json" <<'ZED_KEYMAP'
[
  {
    "context": "Editor && VimControl && !VimWaiting && !menu",
    "bindings": {
      "space f f": "file_finder::Toggle",
      "space f r": "recent_projects::OpenRecent",
      "space e": "pane::RevealInProjectPanel",
      "space g g": "workspace::Open",
      "space b d": "pane::CloseActiveItem",
      "space /": "workspace::NewSearch",
      "space t t": "terminal_panel::ToggleFocus",
      "space l a": "editor::ToggleCodeActions",
      "space l r": "editor::Rename",
      "space l d": "editor::GoToDefinition",
      "space l D": "editor::GoToTypeDefinition",
      "space l i": "editor::GoToImplementation",
      "space l f": "editor::Format",
      "space l h": "editor::Hover",
      "space l n": "editor::GoToDiagnostic",
      "g d": "editor::GoToDefinition",
      "g r": "editor::FindAllReferences",
      "g i": "editor::GoToImplementation",
      "K": "editor::Hover",
      "[ d": "editor::GoToDiagnostic",
      "] d": "editor::GoToDiagnostic"
    }
  },
  {
    "context": "Terminal",
    "bindings": {
      "ctrl-h": ["workspace::ActivatePaneInDirection", "Left"],
      "ctrl-l": ["workspace::ActivatePaneInDirection", "Right"],
      "ctrl-k": ["workspace::ActivatePaneInDirection", "Up"],
      "ctrl-j": ["workspace::ActivatePaneInDirection", "Down"]
    }
  }
]
ZED_KEYMAP

    log_ok "Zed installed and configured as full IDE."
    log_info "Run 'zed .' to open Zed in any project directory."
    log_info "On first launch, Zed will auto-download language servers (LSPs)."
}

# ── Android Studio (via JetBrains Toolbox) ────────────────────────────────────
_install_android_studio() {
    log_section "Android Studio (via JetBrains Toolbox)"

    local TOOLBOX_DIR="$HOME/.local/share/JetBrains/Toolbox"

    if [[ ! -f "$TOOLBOX_DIR/bin/jetbrains-toolbox" ]]; then
        log_step "Downloading JetBrains Toolbox..."
        local toolbox_url
        toolbox_url=$(curl -fsSL "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | \
            jq -r '.TBA[0].downloads.linux.link')

        download "$toolbox_url" /tmp/toolbox.tar.gz
        run tar -xzf /tmp/toolbox.tar.gz -C /tmp/
        local toolbox_bin
        toolbox_bin=$(find /tmp -name "jetbrains-toolbox" -type f 2>/dev/null | head -1)

        if [[ -n "$toolbox_bin" ]]; then
            mkdir -p "$TOOLBOX_DIR/bin"
            run install -m 755 "$toolbox_bin" "$TOOLBOX_DIR/bin/jetbrains-toolbox"
            run rm -f /tmp/toolbox.tar.gz
            log_ok "JetBrains Toolbox installed at $TOOLBOX_DIR/bin/jetbrains-toolbox"
            log_info "Launch Toolbox and install Android Studio from its interface."
        else
            log_warn "JetBrains Toolbox binary not found after extraction."
        fi
    else
        log_info "JetBrains Toolbox already installed."
    fi

    # Desktop entry for Toolbox
    mkdir -p "$HOME/.local/share/applications"
    cat > "$HOME/.local/share/applications/jetbrains-toolbox.desktop" <<DESKTOP
[Desktop Entry]
Name=JetBrains Toolbox
Exec=$TOOLBOX_DIR/bin/jetbrains-toolbox
Icon=jetbrains-toolbox
Type=Application
Categories=Development;IDE;
Comment=JetBrains Toolbox — manage your IDEs
DESKTOP

    log_info "Android Studio deps:"
    apt_install \
        libglu1-mesa \
        libxi6 \
        libxrender1 \
        libxtst6 \
        libfreetype6 \
        libfontconfig1 \
        libxss1 \
        libnss3 \
        libxkbfile1 2>/dev/null || true
}
