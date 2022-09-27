#!/bin/zsh
# shellcheck shell=zsh
autoload -Uz compinit && compinit

source_or_err ~/.zsh_aliases

# Functions are split to individual script files for readability
if [ -d ~/.config/zsh/functions.d ]; then
    for i in ~/.config/zsh/functions.d/*.zsh; do
        if [ -r $i ]; then
            source $i
        fi
    done
    unset i
fi
