# ── Zsh plugins ───────────────────────────────────────────────────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── Options ───────────────────────────────────────────────────────────────────
setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

# ── Zoxide ────────────────────────────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── Starship ──────────────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── fnm (Node version manager) ────────────────────────────────────────────────
eval "$(fnm env --use-on-cd)"

# ── FZF ───────────────────────────────────────────────────────────────────────
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_DEFAULT_OPTS="--height 40% --border --reverse"

# ── Aliases ───────────────────────────────────────────────────────────────────
# File listing
alias ls="eza --icons"
alias ll="eza -la --icons"
alias lt="eza --tree --icons"

# Better defaults
alias cat="bat"
alias cd="z"

# Editors
alias vim="nvim"
alias vi="nvim"

# Git shortcuts
alias lg="lazygit"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph"

# Kubernetes
alias k="kubectl"

# Quick config access
alias cfg="cd ~/.config && nvim ."

# Docker services
alias devdb="docker compose -f ~/Developer/docker-services/compose.yml"

# ── Fastfetch on new shell ────────────────────────────────────────────────────
fastfetch
