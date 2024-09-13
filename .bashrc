#!/bin/bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

shopt -s extglob
# Enable ** globs (if available)
shopt globstar >/dev/null 2>&1 && shopt -s globstar

# shellcheck source=.shenv
source ~/.shenv
PATH=~/.local/share/flatpak/exports/bin:~/workspace/experiments/depot_tools:$PATH


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
  # shellcheck disable=1091
  . /etc/bash_completion
fi


# Load my fancy prompt
source_or_err "${HOME}/.bash-prompt.sh"

# Alias definitions.
source_or_err "${HOME}/.bash_aliases"

# Functions are split to individual script files for readability
if [ -d ~/.config/bash/functions.d ]; then
  for i in ~/.config/bash/functions.d/*.bash; do
    if [ -r "$i" ]; then
      # shellcheck disable=1090
      source_or_err "$i"
    fi
  done
  unset i
fi

# source ~/fzf-tab-completion/bash/fzf-bash-completion.sh
# bind -x '"\t": fzf_bash_completion'

source_or_ignore "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Google cloud
source_or_ignore /snap/google-cloud-cli/current/path.bash.inc
source_or_ignore /snap/google-cloud-cli/current/completion.bash.inc

# [ -f $HOME/workspace/shellcheck-repl/shellcheck-repl.bash ] && source "$HOME/workspace/shellcheck-repl/shellcheck-repl.bash"

# for d in $HOME/workspace/talos/Ava-UI/.git/worktrees/*; do if [ ! -f "$(cat $d/gitdir)" ]; then TARGET=$(cat "$d/gitdir"); mkdir -p $(dirname "$TARGET") && echo "gitdir: $d" > $TARGET; fi; done

command -v direnv &>/dev/null && eval "$(direnv hook bash)"

# Remove duplicate entries from $PATH, keep only the first one (left-to-right) (one final time in case we've added more duplicates in some of the files we sourced)
PATH=$(printf %s "$PATH" | awk -v RS=: '{ if (!arr[$0]++) {printf("%s%s",!ln++?"":":",$0)}}')
export PATH
