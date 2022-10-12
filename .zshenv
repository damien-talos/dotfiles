#!/bin/env zsh

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
    . "$1"
  else
    echo -e "${RED}Unable to find and source $1${RESET}"
  fi
}

source_or_err ~/.sentry_token

## LOAD AVA ENVIRONMENT VARS
source_or_err /Users/damien.schoof/workspace/talos/env/ava-vars.sh
### END LOAD AVA ENVIRONMENT VARS

export NVM_DIR="$HOME/.nvm"
source_or_err "$NVM_DIR/nvm.sh" # This loads nvm

PATH=$(printf %s "$PATH" | awk -v RS=: '{ if (!arr[$0]++) {printf("%s%s",!ln++?"":":",$0)}}')
