typeset -gx -U path
path=( \
    /usr/local/bin(N-/) \
    ~/bin(N-/) \
    ~/.zplug/bin(N-/) \
    ~/.tmux/bin(N-/) \
    /opt/homebrew/bin(N-/) \
    /usr/local/go/bin \
    "$path[@]" \
)

# set fpath before compinit
typeset -gx -U fpath
fpath=( \
    ~/.zsh/Completion(N-/) \
    ~/.zsh/functions(N-/) \
    ~/.zsh/plugins/zsh-completions(N-/) \
    $HOME/.cargo/bin(N-/) \
    /usr/local/share/zsh/site-functions(N-/) \
    $(brew --prefix)/share/zsh/site-functions(N-/) \
    $fpath \
)

. "$HOME/.cargo/env"
