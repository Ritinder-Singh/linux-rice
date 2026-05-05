#!/bin/zsh
# =============================================================================
# macOS Developer Setup Script — mrmackaniel
# =============================================================================
# Run with: chmod +x setup.sh && ./setup.sh
# Safe to re-run — all tools check before installing
# =============================================================================

set -e
echo "Starting macOS Developer Setup..."

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# =============================================================================
# 1. XCODE COMMAND LINE TOOLS
# =============================================================================
echo "\n[1] Installing Xcode Command Line Tools..."
xcode-select --install 2>/dev/null || echo "  Already installed"

# =============================================================================
# 2. HOMEBREW
# =============================================================================
echo "\n[2] Installing Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "  Homebrew already installed"
fi

# =============================================================================
# 2b. MACOS SYSTEM DEFAULTS
# =============================================================================
echo "\n[2b] Configuring macOS system defaults..."

# Key repeat — makes held keys repeat fast (critical for vim)
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Trackpad — tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Screenshots
mkdir -p ~/Pictures/Screenshots
defaults write com.apple.screencapture location ~/Pictures/Screenshots
defaults write com.apple.screencapture type png

# Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 48

# Disable .DS_Store on network/USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Restart affected apps
killall Finder Dock 2>/dev/null || true
echo "  macOS defaults applied"

# =============================================================================
# 3. CORE CLI TOOLS
# =============================================================================
echo "\n[3] Installing core CLI tools..."
brew install git gh curl wget jq yq tree bat eza zoxide \
             htop btop dust duf tmux neofetch starship \
             gpg pinentry-mac openssh bash \
             zsh-autosuggestions zsh-syntax-highlighting

echo "  Remember to configure git after setup:"
echo "     git config --global user.name 'Your Name'"
echo "     git config --global user.email 'you@example.com'"
echo "     gh auth login"

# =============================================================================
# 4. TERMINAL — WezTerm + Font + Starship
# =============================================================================
echo "\n[4] Installing terminal setup..."
brew install --cask wezterm 2>/dev/null || echo "  WezTerm already installed"
brew install --cask font-caskaydia-cove-nerd-font 2>/dev/null || echo "  Font already installed"

mkdir -p ~/.config/wezterm
if [ -f "$DOTFILES_DIR/.config/wezterm/wezterm.lua" ]; then
  cp "$DOTFILES_DIR/.config/wezterm/wezterm.lua" ~/.config/wezterm/wezterm.lua
  echo "  wezterm.lua copied from dotfiles"
else
  cp ~/.config/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua.bak 2>/dev/null || true
  cat > ~/.config/wezterm/wezterm.lua << 'WEZEOF'
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
WEZEOF
fi

echo "\n[5] Configuring Starship prompt..."
mkdir -p ~/.config
if [ -f "$DOTFILES_DIR/.config/starship.toml" ]; then
  cp "$DOTFILES_DIR/.config/starship.toml" ~/.config/starship.toml
  echo "  starship.toml copied from dotfiles"
else
  cat > ~/.config/starship.toml << 'STAREOF'
format = """
[░▒▓](#a3aed2)\
[  ](bg:#a3aed2 fg:#090c0c)\
[](bg:#769ff0 fg:#a3aed2)\
$directory\
[](fg:#769ff0 bg:#394260)\
$git_branch\
$git_status\
[](fg:#394260 bg:#212736)\
$nodejs\
$rust\
$golang\
$python\
$dart\
$swift\
$java\
$haskell\
$c\
[](fg:#212736)\
\n$character"""

[directory]
style = "fg:#e3e5e5 bg:#769ff0"
format = "[ $path ]($style)"
truncation_length = 3

[git_branch]
symbol = ""
style = "bg:#394260"
format = '[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)'

[git_status]
style = "bg:#394260"
format = '[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)'

[nodejs]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[rust]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[golang]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[python]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'
STAREOF
fi

# =============================================================================
# 5. JAVASCRIPT / TYPESCRIPT
# =============================================================================
echo "\n[6] Setting up JavaScript/TypeScript stack..."
brew install fnm

if ! command -v bun &>/dev/null; then
  curl -fsSL https://bun.sh/install | bash
fi
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

eval "$(fnm env --use-on-cd)"
fnm install --lts
fnm use lts-latest
fnm default lts-latest
npm install -g pnpm typescript ts-node

# =============================================================================
# 6. PYTHON
# =============================================================================
echo "\n[7] Setting up Python stack..."
brew install uv pipx
uv python install 3.12
uv python pin 3.12
pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"
pipx install ruff   || true
pipx install httpie || true
pipx install poetry || true

# =============================================================================
# 7. DART / FLUTTER
# =============================================================================
echo "\n[8] Setting up Dart/Flutter stack..."
# fvm manages both Flutter and Dart — no separate dart-sdk brew install needed
brew tap leoafarias/fvm
brew install fvm

fvm install stable
fvm global stable
export PATH="$PATH:$HOME/fvm/default/bin"

# =============================================================================
# 8. SWIFT / iOS
# =============================================================================
echo "\n[9] Setting up Swift/iOS stack..."
if [ ! -d "$HOME/.swiftenv" ]; then
  git clone https://github.com/kylef/swiftenv.git ~/.swiftenv
else
  echo "  swiftenv already installed"
fi
export SWIFTENV_ROOT="$HOME/.swiftenv"
export PATH="$SWIFTENV_ROOT/bin:$SWIFTENV_ROOT/shims:$PATH"

swiftenv install latest 2>/dev/null || echo "  Using system Swift from Xcode"
swiftenv global latest 2>/dev/null || true

brew install fastlane
brew install rbenv ruby-build
rbenv install --skip-existing 3.3.0
rbenv global 3.3.0
eval "$(rbenv init - zsh)"
gem install cocoapods

# =============================================================================
# 9. JAVA / KOTLIN / ANDROID
# =============================================================================
echo "\n[10] Setting up Java/Kotlin/Android stack..."
if [ ! -d "$HOME/.sdkman" ]; then
  curl -s "https://get.sdkman.io" | bash
else
  echo "  SDKMAN already installed"
fi
# Source in a subshell-safe way
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 21-tem 2>/dev/null || sdk install java || true
sdk install maven  || true
sdk install gradle || true
sdk install kotlin || true

# =============================================================================
# 10. GO
# =============================================================================
echo "\n[11] Setting up Go stack..."
# goenv — rbenv-style Go version manager
if [ ! -d "$HOME/.goenv" ]; then
  git clone https://github.com/go-nv/goenv.git ~/.goenv
else
  echo "  goenv already installed"
fi
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)" 2>/dev/null || true
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
unset GOROOT

LATEST_GO=$(goenv install --list 2>/dev/null \
  | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+\s*$' | tail -1 | tr -d ' ')
goenv install "$LATEST_GO" || true
goenv global  "$LATEST_GO" || true

if command -v go &>/dev/null; then
  export GOPROXY=https://proxy.golang.org,direct
  export GONOSUMDB=*
  go install github.com/air-verse/air@latest
  go install github.com/spf13/cobra-cli@latest
else
  echo "  go not in PATH yet — run these manually after restarting shell:"
  echo "     go install github.com/air-verse/air@latest"
  echo "     go install github.com/spf13/cobra-cli@latest"
fi
brew install golangci-lint

# =============================================================================
# 11. RUST
# =============================================================================
echo "\n[12] Setting up Rust stack..."
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
source "$HOME/.cargo/env"
cargo install cargo-binstall
cargo binstall cargo-watch cargo-audit cargo-expand sccache bacon -y

# =============================================================================
# 12. HASKELL
# =============================================================================
echo "\nλ [13] Setting up Haskell stack..."
if ! command -v ghcup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org \
    | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh
else
  echo "  ghcup already installed"
fi
source "$HOME/.ghcup/env" 2>/dev/null || true
ghcup install ghc    recommended || true
ghcup set     ghc    recommended || true
ghcup install cabal  latest      || true
ghcup set     cabal  latest      || true
ghcup install hls    latest      || true

# =============================================================================
# 13. C / C++
# =============================================================================
echo "\n[14] Setting up C/C++ stack..."
brew install llvm cmake ninja vcpkg

# =============================================================================
# 14. EXPERIMENTAL LANGUAGES
# =============================================================================
echo "\nInstalling experimental languages..."

# Zig via zvm (zig version manager)
if ! command -v zvm &>/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash
fi
export PATH="$HOME/.zvm/bin:$PATH"
zvm install master || true
zvm use master     || true

# OCaml via opam — opam manages the compiler itself, no separate brew install
brew install opam
if ! command -v dune &>/dev/null; then
  opam init -y --disable-sandboxing
  eval "$(opam env)"
  opam install dune ocaml-lsp-server ocamlformat -y
else
  echo "  OCaml/opam already configured"
fi

# =============================================================================
# 15. DATABASES (Docker-based)
# =============================================================================
echo "\nSetting up databases..."
mkdir -p ~/Developer/docker-services
cat > ~/Developer/docker-services/compose.yml << 'DBEOF'
services:
  postgres:
    image: postgres:latest
    container_name: local-postgres
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: devdb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:latest
    container_name: local-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
DBEOF
echo "  Compose file written — start with: devdb up -d (after OrbStack is running)"

# =============================================================================
# 16. DEVOPS
# =============================================================================
echo "\nSetting up DevOps tools..."
brew install --cask orbstack 2>/dev/null || echo "  OrbStack already installed"
brew install kubectl helm k9s minikube kind
brew install opentofu terragrunt
brew install nginx caddy act

brew install podman podman-compose
brew install --cask podman-desktop 2>/dev/null || echo "  Podman Desktop already installed"

if ! podman machine list 2>/dev/null | grep -q "podman-machine-default"; then
  podman machine init --cpus 4 --memory 4096 --disk-size 60
fi
podman machine start 2>/dev/null || echo "  Podman machine already running"
podman system service --time=0 unix:///tmp/podman.sock &

# =============================================================================
# 17. ZED EDITOR
# =============================================================================
echo "\n[17] Installing Zed editor..."
brew install --cask zed 2>/dev/null || echo "  Zed already installed"

mkdir -p ~/.config/zed
if [ -f "$DOTFILES_DIR/.config/zed/settings.json" ]; then
  cp "$DOTFILES_DIR/.config/zed/settings.json" ~/.config/zed/settings.json
  cp "$DOTFILES_DIR/.config/zed/keymap.json"   ~/.config/zed/keymap.json
  echo "  Zed config copied from dotfiles"
else
  cat > ~/.config/zed/settings.json << 'ZEDEOF'
{
  "theme": {
    "mode": "dark",
    "light": "One Light",
    "dark": "Tokyo Night"
  },
  "buffer_font_family": "CaskaydiaCove Nerd Font",
  "buffer_font_size": 14,
  "ui_font_size": 16,
  "vim_mode": true,
  "relative_line_numbers": true,
  "tab_size": 2,
  "hard_tabs": false,
  "format_on_save": "on",
  "autosave": "on_focus_change",
  "show_whitespaces": "selection",
  "scrollbar": { "show": "never" },
  "indent_guides": { "enabled": true, "coloring": "indent_aware" },
  "inlay_hints": { "enabled": true },
  "terminal": {
    "font_family": "CaskaydiaCove Nerd Font",
    "font_size": 14,
    "opacity": 0.95,
    "blinking": "off"
  },
  "extensions": [
    "tokyo-night", "toml", "make", "dockerfile",
    "docker-compose", "terraform", "haskell", "ocaml", "zig", "swift"
  ],
  "languages": {
    "TypeScript": { "tab_size": 2 },
    "JavaScript": { "tab_size": 2 },
    "Python":     { "tab_size": 4 },
    "Rust":       { "tab_size": 4 },
    "Go":         { "tab_size": 4 },
    "Swift":      { "tab_size": 4 }
  }
}
ZEDEOF

  cat > ~/.config/zed/keymap.json << 'KEYMAPEOF'
[
  {
    "context": "Editor && vim_mode == normal && !VimWaiting && !menu",
    "bindings": {
      "space e": "project_panel::ToggleFocus",
      "space f": "file_finder::Toggle",
      "space /": "workspace::NewSearch",
      "space b": "tab_switcher::Toggle",
      "space o": "outline::Toggle",
      "space q": "pane::CloseActiveItem",
      "space t": "terminal_panel::ToggleFocus",
      "space g": "git_panel::ToggleFocus",
      "space c a": "editor::ToggleCodeActions",
      "space r n": "editor::Rename",
      "g d": "editor::GoToDefinition",
      "g r": "editor::FindAllReferences",
      "g i": "editor::GoToImplementation",
      "K": "editor::Hover",
      "] d": "editor::GoToDiagnostic",
      "[ d": "editor::GoToPrevDiagnostic"
    }
  }
]
KEYMAPEOF
fi
echo "  Zed config written"

# =============================================================================
# 18. EXTRA TOOLS
# =============================================================================
echo "\nInstalling extra tools..."
brew install ollama
brew install swiftlint
brew install --cask postman        2>/dev/null || echo "  Postman already installed"
brew install --cask android-studio 2>/dev/null || echo "  Android Studio already installed"
brew install --cask obsidian       2>/dev/null || echo "  Obsidian already installed"
brew install ngrok
brew install --cask tailscale      2>/dev/null || echo "  Tailscale already installed"

echo "  Pull Ollama models manually:"
echo "     ollama serve"
echo "     ollama pull llama3 && ollama pull mistral && ollama pull nomic-embed-text"

# =============================================================================
# 19. LINTERS & FORMATTERS
# =============================================================================
echo "\nInstalling linters and formatters..."
npm install -g eslint prettier markdownlint-cli
brew install shellcheck yamllint hadolint

# =============================================================================
# 20. LAZYVIM
# =============================================================================
echo "\nSetting up LazyVim..."
brew install neovim lazygit ripgrep fd fzf

mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null || true
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
mkdir -p ~/.config/nvim/lua/plugins

if [ -f "$DOTFILES_DIR/.config/nvim/lua/plugins/extras.lua" ]; then
  cp "$DOTFILES_DIR/.config/nvim/lua/plugins/extras.lua" ~/.config/nvim/lua/plugins/extras.lua
  cp "$DOTFILES_DIR/.config/nvim/lua/plugins/theme.lua"  ~/.config/nvim/lua/plugins/theme.lua
  echo "  nvim plugins copied from dotfiles"
else
  cat > ~/.config/nvim/lua/plugins/extras.lua << 'NVIMEOF'
return {
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.rust" },
  { import = "lazyvim.plugins.extras.lang.go" },
  { import = "lazyvim.plugins.extras.lang.dart" },
  { import = "lazyvim.plugins.extras.lang.haskell" },
  { import = "lazyvim.plugins.extras.lang.clangd" },
  { import = "lazyvim.plugins.extras.lang.docker" },
  { import = "lazyvim.plugins.extras.lang.terraform" },
  { import = "lazyvim.plugins.extras.lang.swift" },
  { import = "lazyvim.plugins.extras.ui.mini-animate" },
  { import = "lazyvim.plugins.extras.editor.telescope" },
  { import = "lazyvim.plugins.extras.editor.lazygit" },
  { import = "lazyvim.plugins.extras.editor.mini-files" },
  { import = "lazyvim.plugins.extras.coding.mini-surround" },
}
NVIMEOF

  cat > ~/.config/nvim/lua/plugins/theme.lua << 'THEMEEOF'
return {
  {
    "folke/tokyonight.nvim",
    opts = { style = "night", transparent = false },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "tokyonight-night" },
  },
  { "folke/which-key.nvim",     opts = {} },
  { "folke/noice.nvim",         opts = {} },
  { "akinsho/bufferline.nvim",  opts = {} },
  { "folke/trouble.nvim",       opts = {} },
  { "folke/todo-comments.nvim", opts = {} },
}
THEMEEOF
fi

# =============================================================================
# 21. VS CODE
# =============================================================================
echo "\nInstalling VS Code..."
brew install --cask visual-studio-code 2>/dev/null || echo "  VS Code already installed"

VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
mkdir -p "$HOME/Library/Application Support/Code/User"
if [ ! -f "$VSCODE_SETTINGS" ]; then
  cat > "$VSCODE_SETTINGS" << 'VSJSON'
{
  "docker.dockerPath": "/opt/homebrew/bin/podman",
  "docker.context": "default",
  "editor.bracketPairColorization.enabled": true,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode"
}
VSJSON
  echo "  VS Code settings written"
else
  echo "  VS Code settings.json already exists"
fi

echo "\nInstalling VS Code extensions..."
extensions=(
  eamodio.gitlens
  mhutchie.git-graph
  donjayamanne.githistory
  humao.rest-client
  rangav.vscode-thunder-client
  hediet.vscode-drawio
  jebbs.plantuml
  usernamehw.errorlens
  christian-kohler.path-intellisense
  streetsidesoftware.code-spell-checker
  wix.vscode-import-cost
  gruntfuggly.todo-tree
  aaron-bond.better-comments
  ms-kubernetes-tools.vscode-kubernetes-tools
  hashicorp.terraform
  ms-vscode-remote.remote-ssh
  ms-vscode-remote.remote-containers
  yzhang.markdown-all-in-one
  shd101wyy.markdown-preview-enhanced
  davidanson.vscode-markdownlint
  enkia.tokyo-night
  antfu.icons-carbon
  naumovs.color-highlight
)
for ext in "${extensions[@]}"; do
  code --install-extension "$ext" --force 2>/dev/null || echo "  Could not install $ext"
done
echo "  VS Code extensions done"

# =============================================================================
# 22. .ZSHRC — idempotent
# =============================================================================
echo "\nWriting .zshrc..."

zsh_add() {
  grep -qF "$1" ~/.zshrc 2>/dev/null || echo "$1" >> ~/.zshrc
}

zsh_add ""
zsh_add "# ── Homebrew ─────────────────────────────────────────────────────────────────"
zsh_add 'eval "$(/opt/homebrew/bin/brew shellenv)"'

zsh_add "# ── Zsh options & history ────────────────────────────────────────────────────"
zsh_add 'setopt AUTO_CD HIST_IGNORE_DUPS SHARE_HISTORY'
zsh_add 'HISTSIZE=50000; SAVEHIST=50000; HISTFILE=~/.zsh_history'

zsh_add "# ── Zsh plugins ──────────────────────────────────────────────────────────────"
zsh_add 'source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
zsh_add 'source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'

zsh_add "# ── Starship ─────────────────────────────────────────────────────────────────"
zsh_add 'eval "$(starship init zsh)"'

zsh_add "# ── Bun ──────────────────────────────────────────────────────────────────────"
zsh_add 'export BUN_INSTALL="$HOME/.bun"'
zsh_add 'export PATH="$BUN_INSTALL/bin:$PATH"'
zsh_add '[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"'

zsh_add "# ── fnm (Node) ───────────────────────────────────────────────────────────────"
zsh_add 'eval "$(fnm env --use-on-cd)"'

zsh_add "# ── Python (pipx / uv) ───────────────────────────────────────────────────────"
zsh_add 'export PATH="$HOME/.local/bin:$PATH"'

zsh_add "# ── Ruby (rbenv) ─────────────────────────────────────────────────────────────"
zsh_add 'eval "$(rbenv init - zsh)"'

zsh_add "# ── Dart pub cache + fvm ─────────────────────────────────────────────────────"
zsh_add 'export PATH="$PATH:$HOME/.pub-cache/bin"'
zsh_add 'export PATH="$PATH:$HOME/fvm/default/bin"'

zsh_add "# ── Swift (swiftenv) ─────────────────────────────────────────────────────────"
zsh_add 'export SWIFTENV_ROOT="$HOME/.swiftenv"'
zsh_add 'export PATH="$SWIFTENV_ROOT/bin:$SWIFTENV_ROOT/shims:$PATH"'

zsh_add "# ── SDKMAN (Java) ────────────────────────────────────────────────────────────"
zsh_add 'export SDKMAN_DIR="$HOME/.sdkman"'
zsh_add '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"'

zsh_add "# ── Go (goenv) ───────────────────────────────────────────────────────────────"
zsh_add 'export GOENV_ROOT="$HOME/.goenv"'
zsh_add 'export PATH="$GOENV_ROOT/bin:$PATH"'
zsh_add 'eval "$(goenv init -)"'
zsh_add 'export GOPATH="$HOME/go"'
zsh_add 'export PATH="$GOPATH/bin:$PATH"'
zsh_add 'export GOPROXY=https://proxy.golang.org,direct'
zsh_add 'export GONOSUMDB=*'
zsh_add 'export GONOSUMCHECK=*'

zsh_add "# ── Rust ─────────────────────────────────────────────────────────────────────"
zsh_add 'export PATH="$PATH:$HOME/.cargo/bin"'
zsh_add 'export RUSTC_WRAPPER="sccache"'

zsh_add "# ── Haskell ──────────────────────────────────────────────────────────────────"
zsh_add 'export PATH="$PATH:$HOME/.ghcup/bin:$HOME/.cabal/bin"'
zsh_add '[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env"'

zsh_add "# ── LLVM / C++ ───────────────────────────────────────────────────────────────"
zsh_add 'export PATH="$(brew --prefix llvm)/bin:$PATH"'
zsh_add 'export LDFLAGS="-L$(brew --prefix llvm)/lib"'
zsh_add 'export CPPFLAGS="-I$(brew --prefix llvm)/include"'

zsh_add "# ── Zig (zvm) ────────────────────────────────────────────────────────────────"
zsh_add 'export PATH="$HOME/.zvm/bin:$PATH"'

zsh_add "# ── OCaml (opam) ─────────────────────────────────────────────────────────────"
zsh_add '[[ ! -r "$HOME/.opam/opam-init/init.zsh" ]] || source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2>&1'

zsh_add "# ── kubectl autocomplete ─────────────────────────────────────────────────────"
zsh_add 'source <(kubectl completion zsh)'
zsh_add 'complete -F __start_kubectl k'

zsh_add "# ── zoxide (smart cd) ────────────────────────────────────────────────────────"
zsh_add 'eval "$(zoxide init zsh)"'

zsh_add "# ── FZF ──────────────────────────────────────────────────────────────────────"
zsh_add 'source <(fzf --zsh)'
zsh_add 'export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"'
zsh_add 'export FZF_DEFAULT_OPTS="--height 40% --border --reverse"'

zsh_add "# ── Podman socket ────────────────────────────────────────────────────────────"
zsh_add '# export DOCKER_HOST=unix:///tmp/podman.sock'

zsh_add "# ── Aliases ──────────────────────────────────────────────────────────────────"
zsh_add 'alias ls="eza --icons"'
zsh_add 'alias ll="eza -la --icons"'
zsh_add 'alias lt="eza --tree --icons"'
zsh_add 'alias cat="bat"'
zsh_add 'alias cd="z"'
zsh_add 'alias k="kubectl"'
zsh_add 'alias vim="nvim"'
zsh_add 'alias vi="nvim"'
zsh_add 'alias lg="lazygit"'
zsh_add 'alias gs="git status"'
zsh_add 'alias ga="git add"'
zsh_add 'alias gc="git commit"'
zsh_add 'alias gp="git push"'
zsh_add 'alias gl="git log --oneline --graph"'
zsh_add 'alias cfg="cd ~/.config && nvim ."'
zsh_add 'alias devdb="docker compose -f ~/Developer/docker-services/compose.yml"'
zsh_add 'alias podman-start="podman machine start && podman system service --time=0 unix:///tmp/podman.sock &"'
zsh_add 'alias snapshot="dev-snapshot && code ~/dev-snapshot-$(date +%Y-%m-%d).md"'

echo "  .zshrc updated (no duplicates)"

echo "\nSetup complete!"
echo "   Restart your terminal or run: source ~/.zshrc"
echo "   Run: flutter doctor -v        (check Flutter/iOS/Android setup)"
echo "   Run: nvim                     (LazyVim auto-installs plugins on first launch)"
echo "   Run: zed .                    (Zed auto-installs extensions on first launch)"
echo "   Run: sdk list java            (pick a specific JDK if needed)"

# =============================================================================
# 23. SANITY CHECK
# =============================================================================
echo "\nRunning sanity check...\n"

PASS=0
FAIL=0
WARN=0

check() {
  local name=$1
  local cmd=$2
  local result
  result=$(eval "$cmd" 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$result" ]; then
    echo "  [OK] $name — $result"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $name — not found or not working"
    FAIL=$((FAIL + 1))
  fi
}

warn_check() {
  local name=$1
  local cmd=$2
  local result
  result=$(eval "$cmd" 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$result" ]; then
    echo "  [OK] $name — $result"
    PASS=$((PASS + 1))
  else
    echo "  [WARN] $name — not found (may need shell restart)"
    WARN=$((WARN + 1))
  fi
}

echo "── Core ────────────────────────────────────────────────────────────────"
check "Homebrew"    "brew --version | head -1"
check "Git"         "git --version"
check "GitHub CLI"  "gh --version | head -1"
check "Starship"    "starship --version | head -1"
check "WezTerm"     "wezterm --version 2>/dev/null | head -1"
check "Zed"         "zed --version 2>/dev/null | head -1"

echo "\n── JavaScript / TypeScript ─────────────────────────────────────────────"
check "fnm"         "fnm --version"
check "Node"        "node --version"
check "npm"         "npm --version"
check "pnpm"        "pnpm --version"
check "bun"         "bun --version"
check "TypeScript"  "tsc --version"

echo "\n── Python ──────────────────────────────────────────────────────────────"
check "uv"          "uv --version"
check "pipx"        "pipx --version"
check "ruff"        "ruff --version"
check "poetry"      "poetry --version"

echo "\n── Dart / Flutter ──────────────────────────────────────────────────────"
check "Dart"        "dart --version 2>&1 | head -1"
check "fvm"         "fvm --version"
check "Flutter"     "fvm flutter --version 2>/dev/null | head -1"

echo "\n── Swift / iOS ─────────────────────────────────────────────────────────"
check "Swift"       "swift --version 2>&1 | head -1"
check "swiftenv"    "swiftenv --version"
check "Fastlane"    "fastlane --version | tail -1"
check "CocoaPods"   "pod --version"
check "rbenv"       "rbenv --version"

echo "\n── Java / Kotlin / Android ─────────────────────────────────────────────"
check "Java"        "java --version 2>&1 | head -1"
check "Kotlin"      "kotlin -version 2>&1 | head -1"
check "Maven"       "mvn --version | head -1"
check "Gradle"      "gradle --version 2>/dev/null | grep Gradle | head -1"

echo "\n── Go ──────────────────────────────────────────────────────────────────"
check "goenv"           "goenv --version"
check "Go"              "go version"
warn_check "air"        "air -v 2>&1 | head -1"
warn_check "cobra-cli"  "cobra-cli version 2>/dev/null | head -1"
check "golangci-lint"   "golangci-lint --version | head -1"

echo "\n── Rust ────────────────────────────────────────────────────────────────"
check "rustc"           "rustc --version"
check "cargo"           "cargo --version"
check "cargo-binstall"  "cargo-binstall -V"
warn_check "sccache"    "sccache --version"
warn_check "bacon"      "bacon --version"

echo "\n── Haskell ─────────────────────────────────────────────────────────────"
check "ghcup"       "ghcup --version"
warn_check "ghc"    "ghc --version"
warn_check "cabal"  "cabal --version"

echo "\n── C / C++ ─────────────────────────────────────────────────────────────"
check "clang"       "clang --version | head -1"
check "cmake"       "cmake --version | head -1"
check "ninja"       "ninja --version"

echo "\n── Experimental Languages ──────────────────────────────────────────────"
check "zvm"         "zvm --version 2>/dev/null | head -1"
check "Zig"         "zig version"
check "OCaml"       "ocaml --version"
warn_check "opam"   "opam --version"
warn_check "Ruby"   "ruby --version"

echo "\n── DevOps ──────────────────────────────────────────────────────────────"
check "kubectl"     "kubectl version --client 2>&1 | grep -i client | head -1"
check "helm"        "helm version --short"
check "k9s"         "k9s version --short 2>/dev/null | head -1"
check "minikube"    "minikube version | head -1"
check "tofu"        "tofu --version | head -1"
check "terragrunt"  "terragrunt --version"
check "act"         "act --version"
check "Podman"      "podman --version"

echo "\n── Editors ─────────────────────────────────────────────────────────────"
check "Neovim"      "nvim --version | head -1"
check "Zed"         "zed --version 2>/dev/null | head -1"
check "VS Code"     "code --version | head -1"
check "lazygit"     "lazygit --version | head -1"

echo "\n── Extra Tools ─────────────────────────────────────────────────────────"
check "ollama"      "ollama --version"
check "ngrok"       "ngrok version"
check "ripgrep"     "rg --version | head -1"
check "bat"         "bat --version"
check "eza"         "eza --version | head -1"
check "zoxide"      "zoxide --version"
check "fzf"         "fzf --version"

echo "\n── Linters & Formatters ────────────────────────────────────────────────"
check "eslint"          "eslint --version"
check "prettier"        "prettier --version"
check "markdownlint"    "markdownlint --version"
check "shellcheck"      "shellcheck --version | grep version | head -1"
check "yamllint"        "yamllint --version"
check "hadolint"        "hadolint --version"

echo "\n════════════════════════════════════════════════════════════════════════"
echo "  Passed : $PASS"
echo "  Warned : $WARN  (may need shell restart)"
echo "  Failed : $FAIL"
echo "════════════════════════════════════════════════════════════════════════"

if [ $FAIL -eq 0 ]; then
  echo "\n  All checks passed! Your dev machine is ready."
else
  echo "\n  Some tools failed. Try: source ~/.zshrc and re-run."
fi
echo ""
