# .zshrc
#   zshenv -> zprofile -> zshrc (current)
#
# | zshenv   : always
# | zprofile : if login shell
# | zshrc    : if interactive shell
# | zlogin   : if login shell, after zshrc
# | zlogout  : if login shell, after logout
#
# https://zsh.sourceforge.io/Doc/Release/Files.html#Files
#

# Return if zsh is called from Vim
# if [[ -n $VIMRUNTIME ]]; then
#     return 0
# fi

autoload -Uz compinit
compinit

autoload -Uz colors
colors

source <(afx init)
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh
[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && . /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source <(afx completion zsh)


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH="/opt/homebrew/opt/go@1.21/bin:/opt/homebrew/opt/openjdk/bin:$HOME/.npm-packages/bin:$PATH"
# export PATH="/opt/homebrew/opt/openjdk/bin:$HOME/.npm-packages/bin:$PATH"
source /Users/johnbauer/.config/op/plugins.sh

eval "$(direnv hook zsh)"
