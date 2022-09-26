autoload -Uz compinit && compinit

[ -e ~/.zshenv ] && . ~/.zshenv || echo '~/.zshenv does not exist'
[ -e ~/.zsh_aliases ] && . ~/.zsh_aliases || echo '~/.zsh_aliases does not exist'

# Functions are split to individual script files for readability
if [ -d ~/.config/zsh/functions.d ]; then
    for i in ~/.config/zsh/functions.d/*.zsh; do
        if [ -r $i ]; then
            source $i
        fi
    done
    unset i
fi
