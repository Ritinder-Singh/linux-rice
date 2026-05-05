# ── Homebrew ──────────────────────────────────────────────────────────────────
eval "$(/opt/homebrew/bin/brew shellenv)"

# ── Zsh options & history ─────────────────────────────────────────────────────
setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

# ── Zsh plugins ───────────────────────────────────────────────────────────────
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── Starship ──────────────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Bun ───────────────────────────────────────────────────────────────────────
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ── fnm (Node) ────────────────────────────────────────────────────────────────
eval "$(fnm env --use-on-cd)"

# ── Python (pipx / uv) ───────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Ruby (rbenv) ─────────────────────────────────────────────────────────────
eval "$(rbenv init - zsh)"

# ── Dart / Flutter (fvm) ─────────────────────────────────────────────────────
export PATH="$PATH:$HOME/fvm/default/bin"

# ── Swift (swiftenv) ─────────────────────────────────────────────────────────
export SWIFTENV_ROOT="$HOME/.swiftenv"
export PATH="$SWIFTENV_ROOT/bin:$SWIFTENV_ROOT/shims:$PATH"

# ── Java (SDKMAN) ─────────────────────────────────────────────────────────────
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# ── Go (goenv) ───────────────────────────────────────────────────────────────
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
export GOPROXY=https://proxy.golang.org,direct
export GONOSUMDB=*
export GONOSUMCHECK=*

# ── Rust ─────────────────────────────────────────────────────────────────────
export PATH="$PATH:$HOME/.cargo/bin"
export RUSTC_WRAPPER="sccache"

# ── Haskell (ghcup) ──────────────────────────────────────────────────────────
export PATH="$PATH:$HOME/.ghcup/bin:$HOME/.cabal/bin"
[ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env"

# ── LLVM / C++ ───────────────────────────────────────────────────────────────
export PATH="$(brew --prefix llvm)/bin:$PATH"
export LDFLAGS="-L$(brew --prefix llvm)/lib"
export CPPFLAGS="-I$(brew --prefix llvm)/include"

# ── Zig (zvm) ────────────────────────────────────────────────────────────────
export PATH="$HOME/.zvm/bin:$PATH"

# ── OCaml (opam) ─────────────────────────────────────────────────────────────
[[ ! -r "$HOME/.opam/opam-init/init.zsh" ]] || source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2>&1

# ── kubectl autocomplete ─────────────────────────────────────────────────────
source <(kubectl completion zsh)
complete -F __start_kubectl k

# ── zoxide (smart cd) ────────────────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── FZF ──────────────────────────────────────────────────────────────────────
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_DEFAULT_OPTS="--height 40% --border --reverse"

# ── Podman socket ─────────────────────────────────────────────────────────────
# export DOCKER_HOST=unix:///tmp/podman.sock

# ── Aliases ──────────────────────────────────────────────────────────────────
alias ls="eza --icons"
alias ll="eza -la --icons"
alias lt="eza --tree --icons"
alias cat="bat"
alias cd="z"
alias k="kubectl"
alias vim="nvim"
alias vi="nvim"
alias lg="lazygit"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph"
alias cfg="cd ~/.config && nvim ."
alias devdb="docker compose -f ~/Developer/docker-services/compose.yml"
alias podman-start="podman machine start && podman system service --time=0 unix:///tmp/podman.sock &"
alias snapshot="dev-snapshot && code ~/dev-snapshot-$(date +%Y-%m-%d).md"

# ── Claude profiles ───────────────────────────────────────────────────────────
alias claude-personal='CLAUDE_CONFIG_DIR=~/.claude-personal claude'
alias claude-niyukt='CLAUDE_CONFIG_DIR=~/.claude-niyukt claude'

# ── Claude monitor helpers ────────────────────────────────────────────────────
monitor-niyukt() {
  ln -sfn /Users/mrmackaniel/.claude-niyukt /Users/mrmackaniel/.claude
  claude-monitor "$@"
}

monitor-personal() {
  ln -sfn /Users/mrmackaniel/.claude-personal /Users/mrmackaniel/.claude
  claude-monitor "$@"
}

monitor-restore() {
  ln -sfn ~/.claude-backup ~/.claude
}

# ── WezTerm workspace name in Starship prompt ─────────────────────────────────
function set_wezterm_workspace() {
  if [ -n "$WEZTERM_PANE" ]; then
    export WEZTERM_WORKSPACE=$(wezterm cli list 2>/dev/null \
      | awk -v pane="$WEZTERM_PANE" 'NR>1 && $3==pane {print $4}' \
      | head -1)
  fi
}
precmd_functions+=(set_wezterm_workspace)
