# ~/.zshenv — bootstrap only (the one zsh file that MUST live in $HOME).
# It runs before ZDOTDIR is known, so all it does is point zsh at the real
# config directory and load the environment defined there. Everything else
# lives in $ZDOTDIR (~/.config/zsh): .zshenv and .zshrc.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
