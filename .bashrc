#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

shopt -s extglob globstar

PATH=$(yarn global bin):~/bin:~/go/bin:~/.local/share/flatpak/exports/bin:$PATH
export PATH
export EDITOR=code
export FZF_DEFAULT_COMMAND='fd'
export SKIM_DEFAULT_COMMAND="fd --type f || git ls-tree -r --name-only HEAD || rg --files || find ."
export GITHUB_TOKEN=$(cat ~/.github_token)

# Escape code definitions
BLUE='\e[01;34m'
CYAN='\e[01;36m'
WHITE='\e[01;37m'
RED='\e[01;31m'
GREEN='\e[01;32m'
STRIKETRHOUGH='\e[9m'
RESET='\e[00m'

# Shell settings
HISTCONTROL=ignoreboth:erasedups             # Save only one copy of the command
HISTIGNORE='ls:ll:ls -alh:pwd:clear:history' # ignore some additional commands
HISTSIZE=1000                                # custom history size
HISTFILESIZE=100000                          # custom history file size
shopt -s histappend                          # append to history, don't overwrite
shopt -s cmdhist                             # save all lines of a multi-line command in one entry
export CDPATH='.:~/.links'                   # Allow `cd`ing to links in the links directory
shopt -s cdspell                             # Autocorrect typos in cd invocations

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
  . /etc/bash_completion
fi

source_or_err() {
  if [ -f "$1" ]; then
    . "$1"
  else
    echo -e "${RED}Unable to find and source $1${RESET}"
  fi
}

# Load my fancy prompt
source_or_err "${HOME}/.bash-prompt.sh"

# Alias definitions.
source_or_err "${HOME}/.bash_aliases"

# Functions are split to individual script files for readability
if [ -d ~/.config/bash/functions.d ]; then
  for i in ~/.config/bash/functions.d/*.bash; do
    if [ -r $i ]; then
      source $i
    fi
  done
  unset i
fi

# source ~/fzf-tab-completion/bash/fzf-bash-completion.sh
# bind -x '"\t": fzf_bash_completion'

# shellcheck source=/dev/null
source_or_err "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

### LOAD AVA ENVIRONMENT VARS
source_or_err "/home/damien/workspace/talos/env/ava-vars.sh"
### END LOAD AVA ENVIRONMENT VARS

# [ -f /home/damien/workspace/shellcheck-repl/shellcheck-repl.bash ] && source "/home/damien/workspace/shellcheck-repl/shellcheck-repl.bash"

# for d in ~/workspace/talos/Ava-UI/.git/worktrees/*; do if [ ! -f "$(cat $d/gitdir)" ]; then TARGET=$(cat "$d/gitdir"); mkdir -p $(dirname "$TARGET") && echo "gitdir: $d" > $TARGET; fi; done
