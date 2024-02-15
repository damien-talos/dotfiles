# shellcheck shell=bash

source ~/.sh_aliases

alias resource='source ~/.bashrc'
alias edrc='$EDITOR $(readlink -f ~/.bashrc)'
alias lspath="which \$(compgen -A function -abck) | sort -u"
