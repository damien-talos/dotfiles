#!/bin/zsh
# shellcheck shell=zsh
autoload -Uz compinit && compinit

unsetopt auto_cd
export cdpath=($HOME/.links) # Allow `cd`ing to links in the links directory
setopt auto_pushd
setopt chase_links
setopt pushd_ignore_dups
setopt inc_append_history
setopt hist_ignore_dups
setopt hist_expire_dups_first
setopt hist_find_no_dups

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
