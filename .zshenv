#!/bin/env zsh

# zsh startup file order:
# $ZDOTDIR/.zshenv    <-- We are here right now
# $ZDOTDIR/.zprofile
# $ZDOTDIR/.zshrc
# $ZDOTDIR/.zlogin
# $ZDOTDIR/.zlogout

PATH="$HOME/bin:/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
export PATH

eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by Toolbox App
PATH="$PATH:/Users/damien.schoof/Library/Application\ Support/JetBrains/Toolbox/scripts"

source ~/.shenv
