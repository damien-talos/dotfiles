#!/bin/bash
# --------------------------------------------- #
# Clear the screen or a given file / directory  #
# --------------------------------------------- #

# Get command info
CMD_PWD=$(pwd)
CMD="$0"
# CMD_DIR="$(cd "$(dirname "$CMD")" && pwd -P)"
RED='\033[01;31m'
RESET='\033[00m'

# Show help function to be used below
clear_show_help() {
    awk 'NR>1{print} /^(###|$)/{exit}' "$CMD"
    echo "$CMD clears the screen or a given file(s)"
    echo "USAGE: $(basename "$CMD") [arguments]"
    echo "ARGS:"
    MSG=$(awk '/# BEGIN_KNOWN_ALIASES/,/# END_KNOWN_ALIASES/' "$CMD" | sed -e 's/^[[:space:]]*//' -e 's/|/\t/' -n '/^[[:alpha:]]+\\)/p') # | awk '/^\w/ {printf "  %s\n", $1}')
    echo -e "$MSG"
    EMSG=$(eval "echo \"$MSG\"")
    echo "$EMSG"
}

clear() {
    if [[ $# -eq 0 ]]; then
        # clear the screen
        command clear
    elif [[ $# -eq 1 && ! -e "$1" ]]; then
        # Magic to clear log file directories easily
        case "$1" in
        # BEGIN_KNOWN_ALIASES
        dev.local)
            if [[ -d "~/workspace/talos/ava/logs" ]]; then clear ~/workspace/talos/ava/logs/*; fi
            ;;
        # END_KNOWN_ALIASES
        *)
            echo "Unknown clear target $1 does not exist"
            clear_show_help
            ;;
        esac
    else
        for arg in "$@"; do
            # clear the contents of all files passed as args
            echo "" >$arg
        done
    fi
}

if [[ "$0" == "$ZSH_ARGZERO" ]]; then
    # Script was run as a command
    clear $*
fi
