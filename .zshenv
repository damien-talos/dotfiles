#!/bin/env zsh

# zsh startup file order:
# $ZDOTDIR/.zshenv    <-- We are here right now
# $ZDOTDIR/.zprofile
# $ZDOTDIR/.zshrc
# $ZDOTDIR/.zlogin
# $ZDOTDIR/.zlogout

PATH="$HOME/bin:/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
# Remove duplicate entries from PATH - this can happen if we re-source our files
export PATH
export EDITOR=code
GITHUB_TOKEN=$(cat ~/.github_token)
export GITHUB_TOKEN

RED='\033[01;31m'
RESET='\033[00m'

source_or_err() {
  if [ -f "$1" ]; then
    # shellcheck disable=1090
    . "$1"
  else
    echo -e "${RED}Unable to find and source $1${RESET}"
  fi
}
source_or_ignore() {
  if [ -f "$1" ]; then
    # shellcheck disable=1090
    . "$1"
  else
    echo -e "${GRAY}Unable to find and source $1${RESET}"
  fi
}

source_or_err ~/.sentry_token
source_or_err ~/.shortcut_token

eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by Toolbox App
PATH="$PATH:/Users/damien.schoof/Library/Application Support/JetBrains/Toolbox/scripts"

## LOAD AVA ENVIRONMENT VARS
source_or_err /Users/damien.schoof/workspace/talos/env/ava-vars.sh
### END LOAD AVA ENVIRONMENT VARS

export NVM_DIR="$HOME/.nvm"
source_or_ignore "$NVM_DIR/nvm.sh" # This loads nvm

source_or_ignore "$HOME/.rvm/scripts/rvm"

source_or_ignore "$HOME/.cargo/env"
# bun completions
source_or_err "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
PATH="$BUN_INSTALL/bin:$PATH"

# Remove duplicate entries from $PATH, keep only the first one (left-to-right)
export PATH=$(printf %s "$PATH" | awk -v RS=: '{ if (!arr[$0]++) {printf("%s%s",!ln++?"":":",$0)}}')
