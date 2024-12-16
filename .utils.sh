#!/bin/bash

# Escape code definitions
# BLUE='\033[01;34m'
# CYAN='\033[01;36m'
# WHITE='\033[01;37m'
RED='\033[01;31m'
GRAY='\033[01;30;1m'
# GREEN='\033[01;32m'
# STRIKETRHOUGH='\033[9m'
RESET='\033[00m'

# read_env_variable_from_file <variable_name>
read_env_variable_from_file() {
  variable_name="${1:u}_TOKEN"
  file_name="${2:-$HOME/.${1}_token}"
  if [ -f "$file_name" ]; then
    export "$variable_name"="$(cat "$file_name")"
  else
    echo -e "${GRAY}Unable to find $file_name${RESET}"
  fi
}

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
    . "$@"
  else
    echo -e "${GRAY}Unable to find and source $1${RESET}"
  fi
}
