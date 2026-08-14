# Homebrew 6 won't load formulae from a non-official tap until they're trusted.
# `trusted:` declares that here rather than shelling out to `brew trust` first:
# bundle resolves each item against the tap's clone_target, so for the URL taps
# below it writes the URL-bound entry Homebrew actually checks — which is the one
# thing `brew trust --formula livekit/nebula/nebula` can NOT do on a fresh
# machine, where the tap has no remote yet and only the bare name is available.
# Trust is applied before anything fetches, so `brew bundle` alone is enough.
tap "cockroachdb/tap", trusted: { formula: "cockroach" }
tap "hashicorp/tap", trusted: { formulae: ["terraform", "terraform-ls"] }
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
brew "docker"
brew "exiftool"
brew "eza"
brew "ffmpeg"
brew "fd"
brew "fnm"
brew "fzf"
brew "gawk"
brew "gifsicle"
brew "git-delta"
brew "gnu-sed"
brew "go"
brew "gopls"
brew "goreleaser"
brew "grep"
brew "gum"
brew "helmfile"
brew "hugo"
brew "jq"
brew "k9s"
brew "kubernetes-cli"
brew "kustomize"
brew "litecli"
brew "lua-language-server"
brew "luarocks"
brew "mas"
brew "mysql"
brew "neovim"
brew "protobuf"
brew "ripgrep"
brew "rust"
brew "rustup"
brew "saml2aws"
brew "starship"
brew "stylua"
brew "tmux"
brew "tree-sitter"
brew "ttyd"
brew "typescript-language-server"
brew "uv"
brew "vhs"
brew "wget"
brew "yarn"
brew "zoxide"
brew "zsh"
brew "cockroachdb/tap/cockroach"
brew "hashicorp/tap/terraform"
brew "hashicorp/tap/terraform-ls"
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
cask "ghostty"
cask "hammerspoon"
cask "hiddenbar"
cask "inkdrop"
cask "numi"
cask "obs"
cask "obsidian"
cask "path-finder"
cask "popclip"
cask "qlmarkdown"
cask "tableplus"
cask "the-unarchiver"
cask "typora"
cask "wezterm"
