#!/bin/bash
# --------------------------------------------- #
# Set battery charge parameters #
# --------------------------------------------- #

# Get command info
CMD_PWD=$(pwd)
CMD="$0"
CMD_DIR="$(cd "$(dirname "$CMD")" && pwd -P)"
RED='\033[01;31m'
RESET='\033[00m'

# BEGIN SCRIPT VARIABLES
[ -n "$VERBOSE" ] || VERBOSE=0
[ -n "$FULL_CHARGE" ] || FULL_CHARGE=0
[ -n "$ONCE" ] || ONCE=0
# END SCRIPT VARIABLES

out() { echo -e "$(date +%Y-%m-%dT%H:%M:%SZ): $*"; }
err() { out "$*" 1>&2; }
vrb() { if [ $VERBOSE -gt 1 ]; then out "$@"; fi; }
dbg() { if [ $VERBOSE -gt 0 ]; then err "$@"; fi; }
die() { err "EXIT: ${RED}$1${RESET}" && [ "$2" ] && [ "$2" -ge 0 ] && exit "$2" || exit 1; }

# Show help function to be used below
show_help() {
    awk 'NR>1{print} /^(###|$)/{exit}' "$CMD"
    echo "Configures certain battery charge parameters"
    echo "USAGE: $(basename "$CMD") [arguments] [pull request id]"
    echo "ARGS:"
    MSG=$(awk '/# BEGIN SWITCHES/,/# END SWITCHES/' "$CMD" | sed -e 's/^[[:space:]]*//' -e 's/|/\t/' -e 's/)/\t/' | awk -F'\t' '/^-/ {printf "  %-6s%-20s%s\n", $1, $2, $3}')
    # echo -e "$MSG"
    EMSG=$(eval "echo \"$MSG\"")
    echo "$EMSG"
}

show_variables() {
    MSG=$(awk '/# BEGIN SCRIPT VARIABLES/,/# END SCRIPT VARIABLES/{if (match($0,/# END SCRIPT VARIABLES/)) exit; print;}' "$CMD" |
        sed -e '/^#/d' -e 's/^\[ -n "\$//' -e 's/".*//' |
        sed -Ee 's/(.+)/dbg "\1=\${\1}"/')
    eval "$MSG"
}

POSITIONAL=()

NARGS=-1
while [ "$#" -ne "$NARGS" ]; do
    NARGS=$#
    case $1 in
    # BEGIN SWITCHES
    -h | --help) # This help message
        show_help
        exit 0
        ;;
    -v | --verbose) # Enable verbose messages (DEFAULT: $VERBOSE)
        VERBOSE=$((VERBOSE + 1)) && shift && vrb "#-INFO: VERBOSE=$VERBOSE" ;;
    -f | --fullcharge) # Set battery to charge fully (till next reboot)
        shift && FULL_CHARGE=1 && vrb "#-INFO: FULL_CHARGE=$FULL_CHARGE" ;;
    -o | --once) # Set battery to charge fully only one time (will reset when switched to battery power)
        shift && ONCE=1 && vrb "#-INFO: ONCE=$ONCE" ;;
    *) # unknown option, save it in an array for later
        # if [ "${1:0:1}" = "-" ]; then
        #     new_args=$(echo "$1" | grep -o '[[:alnum:]]' | sed -E -e 's/^/-/')
        #     echo "${new_args}"
        # fi
        POSITIONAL+=("$1") && shift
        ;;
        # END SWITCHES
    esac
done

set -- "${POSITIONAL[@]}"

if [ $VERBOSE -gt 0 ]; then
    show_variables
fi

if [[ $ONCE == 1 ]]; then
    RESTORE_THRESHOLDS_ON_BAT=1 sudo tlp fullcharge
elif [[ $FULL_CHARGE == 1 ]]; then
    sudo tlp fullcharge
fi

exit 0
