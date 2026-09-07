# Homebrew 6 won't load formulae from a non-official tap until they're trusted.
# `trusted:` declares that here rather than shelling out to `brew trust` first:
# bundle resolves each item against the tap's clone_target, so for the URL taps
# below it writes the URL-bound entry Homebrew actually checks — which is the one
# thing `brew trust --formula livekit/nebula/nebula` can NOT do on a fresh
# machine, where the tap has no remote yet and only the bare name is available.
# Trust is applied before anything fetches, so `brew bundle` alone is enough.
tap "cockroachdb/tap", trusted: { formula: "cockroach" }
# LiveKit's taps live in the tool repos themselves, not in a homebrew-<name>
# repo, so the git URL is required — the bare name would resolve to
# livekit/homebrew-lkctl, which doesn't exist. nebula and nats need their own
# trust despite being unlisted below: lkctl loads them as dependencies, and
# trusting lkctl does not trust what it pulls in.
tap "livekit/lkctl", "https://github.com/livekit/lkctl.git", trusted: { formula: "lkctl" }
tap "livekit/nebula", "https://github.com/livekit/nebula.git", trusted: { formula: "nebula" }
tap "nats-io/nats-tools", trusted: { formula: "nats" }
brew "awscli"
brew "bat"
brew "colima"
brew "direnv"
brew "docker"   # the CLI; colima is the daemon
brew "eza"
brew "fd"
brew "flyctl"
brew "fnm"
brew "fzf"
brew "gawk"
brew "gh"
brew "git-delta"
brew "gnu-sed"
brew "go"
brew "golangci-lint"
brew "gopls"
brew "grep"
brew "helmfile"
brew "jq"
brew "k9s"
brew "kubernetes-cli"
brew "kustomize"
brew "lua-language-server"
brew "luarocks"
brew "neovim"
brew "ripgrep"
# rustup only — it conflicts with the `rust` formula, and the toolchain it
# manages lives in ~/.cargo (cargo/rustc resolve there; see .zprofile).
brew "rustup"
brew "saml2aws"
brew "starship"
brew "stylua"
brew "tmux"
# The CLI, not the library: Homebrew split `tree-sitter` into a lib-only formula
# and a separate `tree-sitter-cli`. nvim-treesitter (main) shells out to the CLI
# to fetch/compile parsers; the bare `tree-sitter` gave only libtree-sitter, which
# nothing here links, so a node-based npm `tree-sitter-cli` had crept onto PATH
# and broke parser installs whenever node was mid-upgrade. This is the native
# Rust binary — no node dependency.
brew "tree-sitter-cli"
brew "typescript-language-server"
brew "uv"
brew "wget"
brew "yarn"
brew "zoxide"
brew "zsh"
brew "cockroachdb/tap/cockroach"
# lkctl pulls nebula (required) and nats (recommended) with it, so neither is
# listed — but both taps above are, since a URL tap can't be resolved from the
# dependency name alone. `cockroach` is NOT a transitive dep: lkctl shells out
# to it by name (`cockroach sql --url …`) for `lkctl cockroach connect`.
brew "livekit/lkctl/lkctl"
cask "1password-cli"
cask "claude-code"
cask "font-commit-mono"
cask "font-fira-code"
cask "font-hack-nerd-font"
cask "font-ioskeley-mono"
cask "font-jetbrains-mono"
# Links gcloud/gsutil/bq into the brew prefix, so the SDK's own path.zsh.inc is
# redundant. $ZDOTDIR/.zshrc sources its completion.zsh.inc from here.
cask "gcloud-cli"
cask "ghostty"
cask "hammerspoon"
cask "obs"
cask "path-finder"
cask "qlmarkdown"
cask "tableplus"
cask "the-unarchiver"
# The nightly, not the stable cask: both install WezTerm.app, so listing the
# one that is not installed makes `brew bundle` abort on the existing app.
cask "wezterm@nightly"
