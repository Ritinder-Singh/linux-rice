#!/bin/zsh
# =============================================================================
# dev-snapshot.sh — mrmackaniel
# Auto-discovers ALL dev tools, languages, and packages on your system
# Usage: ./dev-snapshot.sh
# Output: ~/dev-snapshot-<date>.md
# =============================================================================

# =============================================================================
# HELPERS  (defined at top level so subshells can inherit them)
# =============================================================================

has() { command -v "$1" &>/dev/null; }

auto_version() {
  local bin=$1
  local ver=""
  for flag in "--version" "-version" "-V" "version" "--Version"; do
    ver=$("$bin" $flag 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    [[ -n "$ver" ]] && echo "$ver" && return
  done
  echo "installed"
}

categorize() {
  local bin=$1
  case $bin in
    node|nodejs|deno|python*|python|ruby|perl|lua*|lua|php*|R|Rscript|julia|elixir|iex|erlang|erl|java|javac|kotlin|scala|clojure|groovy|dart|swift|go|rustc|ghc|ghci|ocaml|zig|nim|crystal|racket|scheme|guile|sbcl|clisp|idris|fsharp|dotnet|mono)
      echo "Languages & Runtimes" ;;
    fnm|nvm|nodenv|pyenv|rbenv|rvm|chruby|swiftenv|ghcup|rustup|g|gvm|goenv|goenv|jabba|asdf|mise|volta|proto|fvm|dvm|zvm)
      echo "Version Managers" ;;
    npm|yarn|pnpm|bun|pip|pip3|pipx|uv|poetry|pdm|conda|mamba|cargo|gem|bundler|composer|mix|opam|cabal|stack|pub|brew)
      echo "Package Managers" ;;
    make|cmake|ninja|meson|bazel|just|task|xcodebuild|fastlane|gradle|mvn|ant|sbt|dune)
      echo "Build Tools" ;;
    eslint|prettier|biome|ruff|black|flake8|pylint|mypy|rubocop|golangci-lint|gofmt|rustfmt|hlint|ocamlformat|clang-format|shellcheck|shfmt|yamllint|hadolint|markdownlint|stylelint|tslint)
      echo "Linters & Formatters" ;;
    rust-analyzer|clangd|pyright|typescript-language-server|bash-language-server|yaml-language-server|haskell-language-server|ocamllsp|zls|solargraph|ruby-lsp)
      echo "Language Servers" ;;
    docker|podman|nerdctl|buildah|skopeo|kubectl|helm|k9s|minikube|kind|k3s|flux|argocd|terraform|tofu|terragrunt|pulumi|aws|gcloud|az|doctl|fly|heroku|nomad|consul|vault|packer|act)
      echo "Containers & Cloud" ;;
    psql|mysql|mysqldump|redis-cli|mongosh|sqlite3|cockroach|influx)
      echo "Databases" ;;
    git|gh|hub|glab|tig|lazygit|gitui|delta|git-lfs)
      echo "Git & VCS" ;;
    tmux|screen|zellij|starship|bat|eza|exa|lsd|fd|fzf|rg|ag|jq|yq|zoxide|htop|btop|dust|duf|hyperfine|entr|parallel|nvim|vim|emacs|nano|helix|hx|zed)
      echo "Terminal & Shell Tools" ;;
    ollama|llm|aichat|sgpt|tgpt|ffmpeg|imagemagick|convert|whisper)
      echo "AI & ML Tools" ;;
    ngrok|cloudflared|tailscale|openssl|gpg|age|op|nmap|trivy|grype|syft|cosign|mosh)
      echo "Network & Security" ;;
    cargo-binstall|cargo-watch|cargo-audit|cargo-expand|sccache|bacon|air|cobra-cli|wezterm|alacritty|kitty|ripgrep|fd|bat|eza|fzf|zoxide|btop|dust|duf|tmux|starship|neofetch|fastfetch|hyperfine|entr|vcpkg)
      echo "Dev Utilities" ;;
    *)
      echo "" ;;
  esac
}

# =============================================================================
# MAIN — wraps everything so `local` is valid
# =============================================================================
main() {
  local OUTPUT="$HOME/dev-snapshot-$(date +%Y-%m-%d).md"
  local HOSTNAME_SHORT
  HOSTNAME_SHORT=$(hostname -s)
  local OS_VERSION
  OS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
  local ARCH
  ARCH=$(uname -m)

  echo "Taking live dev environment snapshot..."
  echo "   Output: $OUTPUT"
  echo "   This may take 30-60 seconds...\n"

  # ── Known dev binaries to check ──────────────────────────────────────────
  local -a KNOWN_BINS=(
    node nodejs deno python python3 ruby perl lua php R julia elixir erlang
    java javac kotlin scala clojure groovy dart flutter swift go rustc ghc ocaml
    zig nim crystal racket sbcl dotnet mono fsharp
    fnm nvm nodenv pyenv rbenv rvm swiftenv ghcup rustup g gvm goenv asdf mise volta fvm zvm
    npm yarn pnpm bun pip pip3 pipx uv poetry pdm conda mamba cargo gem bundler
    composer mix opam cabal stack pub brew
    make cmake ninja meson bazel just task xcodebuild fastlane gradle mvn ant sbt dune
    eslint prettier biome ruff black flake8 pylint mypy rubocop golangci-lint gofmt
    rustfmt hlint ocamlformat clang-format shellcheck shfmt yamllint hadolint markdownlint
    rust-analyzer clangd pyright typescript-language-server haskell-language-server ocamllsp zls ruby-lsp
    docker podman kubectl helm k9s minikube kind tofu terraform terragrunt pulumi
    aws gcloud az doctl fly heroku vault packer act
    psql mysql redis-cli mongosh sqlite3
    git gh hub glab tig lazygit gitui delta
    tmux screen zellij starship bat eza fd fzf rg jq yq zoxide htop btop dust nvim vim zed
    ollama llm ffmpeg imagemagick
    ngrok cloudflared tailscale openssl gpg op nmap trivy mosh
    cargo-binstall cargo-watch cargo-audit cargo-expand sccache bacon air cobra-cli
    vcpkg wezterm alacritty kitty neofetch fastfetch hyperfine entr
    code cursor subl atom
  )

  # ── Also scan actual PATH entries ────────────────────────────────────────
  local -a PATH_BINS=()
  local dir
  for dir in ${(s/:/)PATH}; do
    [[ -d "$dir" ]] || continue
    local bin
    for bin in "$dir"/*(N:t); do
      PATH_BINS+=("$bin")
    done
  done

  local -a ALL_BINS=("${KNOWN_BINS[@]}" "${PATH_BINS[@]}")

  # ── Discover and categorize ───────────────────────────────────────────────
  echo "  Scanning PATH for dev tools..."
  typeset -A FOUND_TOOLS
  typeset -A SEEN_BINS

  local bin cat ver fpath
  for bin in "${ALL_BINS[@]}"; do
    [[ -n "${SEEN_BINS[$bin]}" ]] && continue
    SEEN_BINS[$bin]=1

    has "$bin" || continue

    cat=$(categorize "$bin")
    [[ -z "$cat" ]] && continue

    ver=$(auto_version "$bin")
    fpath=$(which "$bin" 2>/dev/null)

    FOUND_TOOLS[$bin]="${cat}|${ver}|${fpath}"
  done

  echo "  Found ${#FOUND_TOOLS} dev tools\n"

  # ── Write markdown ────────────────────────────────────────────────────────
  {

  cat << HEADER
# Dev Environment Snapshot
> **Machine:** $HOSTNAME_SHORT
> **OS:** macOS $OS_VERSION ($ARCH)
> **Generated:** $(date "+%A %d %B %Y at %H:%M")
> **Shell:** $(basename $SHELL) $ZSH_VERSION
> **Total dev tools found:** ${#FOUND_TOOLS}

---

HEADER

  # Summary table
  echo "## Summary"
  echo ""
  echo "| Category | Tools Found |"
  echo "|----------|-------------|"

  typeset -A CAT_COUNTS
  local tcat
  for bin in "${(@k)FOUND_TOOLS}"; do
    tcat="${FOUND_TOOLS[$bin]%%|*}"
    CAT_COUNTS[$tcat]=$((${CAT_COUNTS[$tcat]:-0} + 1))
  done
  for tcat in "${(@ko)CAT_COUNTS}"; do
    echo "| $tcat | ${CAT_COUNTS[$tcat]} |"
  done
  echo "| **Total** | **${#FOUND_TOOLS}** |"

  # Tools by category
  local -a CATEGORIES=(
    "Languages & Runtimes"
    "Version Managers"
    "Package Managers"
    "Build Tools"
    "Linters & Formatters"
    "Language Servers"
    "Containers & Cloud"
    "Databases"
    "Git & VCS"
    "Terminal & Shell Tools"
    "AI & ML Tools"
    "Network & Security"
    "Dev Utilities"
  )

  local cat_entry tool_cat rest
  local -a tools_in_cat
  for cat_entry in "${CATEGORIES[@]}"; do
    tools_in_cat=()
    for bin in "${(@ko)FOUND_TOOLS}"; do
      tool_cat="${FOUND_TOOLS[$bin]%%|*}"
      [[ "$tool_cat" == "$cat_entry" ]] && tools_in_cat+=("$bin")
    done
    [[ ${#tools_in_cat} -eq 0 ]] && continue

    echo ""
    echo "## $cat_entry"
    echo ""
    echo "| Tool | Version | Path |"
    echo "|------|---------|------|"
    for bin in "${tools_in_cat[@]}"; do
      rest="${FOUND_TOOLS[$bin]#*|}"
      ver="${rest%%|*}"
      fpath="${rest##*|}"
      echo "| \`$bin\` | $ver | $fpath |"
    done
  done

  # ── Detailed package lists ────────────────────────────────────────────────
  echo ""
  echo "---"
  echo ""
  echo "## Installed Packages (Detailed)"

  echo ""
  echo "### Homebrew Formulae"
  echo '```'
  brew list --formula 2>/dev/null | tr ' ' '\n' | sort || echo "not available"
  echo '```'

  echo ""
  echo "### Homebrew Casks"
  echo '```'
  brew list --cask 2>/dev/null | tr ' ' '\n' | sort || echo "not available"
  echo '```'

  echo ""
  echo "### Node Versions (fnm)"
  echo '```'
  fnm list 2>/dev/null || echo "not available"
  echo '```'

  echo ""
  echo "### Global npm Packages"
  echo '```'
  npm list -g --depth=0 2>/dev/null || echo "not available"
  echo '```'

  echo ""
  echo "### Python Versions (uv)"
  echo '```'
  uv python list 2>/dev/null || echo "not available"
  echo '```'

  echo ""
  echo "### pipx Packages"
  echo '```'
  pipx list 2>/dev/null || echo "not available"
  echo '```'

  echo ""
  echo "### Ruby Versions (rbenv)"
  echo '```'
  rbenv versions 2>/dev/null || echo "not available"
  echo '```'

  echo ""
  echo "### Flutter Versions (fvm)"
  echo '```'
  fvm list 2>/dev/null || echo "not available"
  echo '```'

  echo ""
  echo "### Java Versions (SDKMAN)"
  echo '```'
  sdk list java 2>/dev/null | grep -E "installed|local" | head -20 || echo "not available"
  echo '```'

  echo ""
  echo "### Rust Toolchains"
  echo '```'
  rustup toolchain list 2>/dev/null || echo "not available"
  echo '```'

  echo ""
  echo "### Cargo Binaries (~/.cargo/bin)"
  echo '```'
  ls ~/.cargo/bin/ 2>/dev/null | sort || echo "not available"
  echo '```'

  echo ""
  echo "### GHC/Haskell (ghcup)"
  echo '```'
  ghcup list 2>/dev/null | grep -v "^$" | head -20 || echo "not available"
  echo '```'

  echo ""
  echo "### Go Binaries (~/go/bin)"
  echo '```'
  ls ~/go/bin/ 2>/dev/null | sort || echo "not available"
  echo '```'

  echo ""
  echo "### OCaml Packages (opam)"
  echo '```'
  opam list --short 2>/dev/null | head -40 || echo "not available"
  echo '```'

  echo ""
  echo "### VS Code Extensions"
  echo '```'
  code --list-extensions 2>/dev/null | sort || echo "not available"
  echo '```'

  echo ""
  echo "### Ollama Models"
  echo '```'
  ollama list 2>/dev/null || echo "Ollama not running — start with: ollama serve"
  echo '```'

  # ── Environment ───────────────────────────────────────────────────────────
  echo ""
  echo "---"
  echo ""
  echo "## Environment"

  echo ""
  echo "### Key Variables"
  echo "| Variable | Value |"
  echo "|----------|-------|"
  local env_var env_val
  for env_var in GOPATH GOROOT GOPROXY GONOSUMDB CARGO_HOME RUSTC_WRAPPER \
                 SDKMAN_DIR SWIFTENV_ROOT BUN_INSTALL DOCKER_HOST JAVA_HOME \
                 PYTHONPATH VIRTUAL_ENV NODE_PATH ANDROID_HOME FLUTTER_ROOT \
                 HOMEBREW_PREFIX HOMEBREW_CELLAR; do
    env_val="${(P)env_var}"
    [[ -n "$env_val" ]] && echo "| \`$env_var\` | \`$env_val\` |"
  done

  echo ""
  echo "### PATH"
  echo '```'
  echo $PATH | tr ':' '\n'
  echo '```'

  echo ""
  echo "### Disk Usage by Tool"
  echo '```'
  local disk_entry disk_dir disk_label
  for disk_entry in \
    "$HOME/.cargo:Rust (cargo)" \
    "$HOME/.rustup:Rust (rustup)" \
    "$HOME/go:Go" \
    "$HOME/.ghcup:Haskell (ghcup)" \
    "$HOME/.sdkman:SDKMAN" \
    "$HOME/.rbenv:Ruby (rbenv)" \
    "$HOME/.opam:OCaml (opam)" \
    "$HOME/.pub-cache:Dart pub cache" \
    "$HOME/fvm:Flutter (fvm)" \
    "$HOME/.bun:Bun" \
    "$HOME/.local/share/fnm:Node (fnm)" \
    "$HOME/.local/share/uv:Python (uv)" \
    "$HOME/.config/nvim:Neovim config" \
    "$HOME/.config/zed:Zed config" \
    "/opt/homebrew:Homebrew"; do
    disk_dir="${disk_entry%%:*}"
    disk_label="${disk_entry##*:}"
    [[ -d "$disk_dir" ]] && printf "%-10s  %s\n" "$(du -sh "$disk_dir" 2>/dev/null | cut -f1)" "$disk_label"
  done
  echo '```'

  cat << FOOTER

---

## How to Update Everything

\`\`\`bash
# Package managers
brew update && brew upgrade && brew upgrade --cask

# Language toolchains
rustup update
ghcup upgrade
sdk selfupdate

# Global packages
pipx upgrade-all
npm update -g
cargo install-update -a  # needs: cargo install cargo-update
\`\`\`

---
*Generated by dev-snapshot.sh on $(date)*
*Drop this file into a Claude chat for fully context-aware dev assistance.*
FOOTER

  } > "$OUTPUT"

  echo "Snapshot complete!"
  echo "   $(wc -l < "$OUTPUT" | tr -d ' ') lines written to $OUTPUT"
  echo ""
  echo "Quick actions:"
  echo "   open $OUTPUT"
  echo "   code $OUTPUT"
  echo "   cat $OUTPUT | pbcopy"
}

main "$@"
