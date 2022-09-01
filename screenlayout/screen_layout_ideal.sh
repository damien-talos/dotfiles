#!/bin/bash
# ------------------------------------------------ #
# Set current screen layout to my preferred layout #
# ------------------------------------------------ #

set -eo pipefail

# Get command info
CMD_PWD=$(pwd)
CMD="$0"
CMD_DIR="$(cd "$(dirname "$CMD")" && pwd -P)"
RED='\033[01;31m'
STRIKETHROUGH='\e[9m'
RESET='\033[00m'

ansi() { echo -en "\e[${1}m${*:2}\e[0m"; }
bold() { ansi 1 "$@"; }
italic() { ansi 3 "$@"; }
underline() { ansi 4 "$@"; }
strikethrough() { ansi 9 "$@"; }
red() { ansi 31 "$@"; }

# BEGIN SCRIPT VARIABLES
[ -n "$VERBOSE" ] || VERBOSE=0
# END SCRIPT VARIABLES

out() { echo -e "$(date +%Y-%m-%dT%H:%M:%SZ): $*"; }
err() { out "$*" 1>&2; }
vrb() { if [ $VERBOSE -gt 1 ]; then out "$@"; fi; }
dbg() { if [ $VERBOSE -gt 0 ]; then err "$@"; fi; }
die() { err "EXIT: ${RED}$1${RESET}" && [ "$2" ] && [ "$2" -ge 0 ] && exit "$2" || exit 1; }

# Show help function to be used below
show_help() {
    awk 'NR>1{print} /^(###|$)/{exit}' "$CMD"
    # echo "review checks out a git worktree into the ramdisk"
    echo "USAGE: $(basename "$CMD") [arguments]"
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
    -vv | --verbose) # Enable verbose messages (DEFAULT: $VERBOSE)
        VERBOSE=$((VERBOSE + 2)) && shift && vrb "#-INFO: VERBOSE=$VERBOSE" ;;
    -v | --debug) # Enable verbose messages (DEFAULT: $VERBOSE)
        VERBOSE=$((VERBOSE + 1)) && shift && vrb "#-INFO: VERBOSE=$VERBOSE" ;;
    esac
    # END SWITCHES
done

# DisplayPort-0: USB-C monitor from laptop
# DisplayPort-2: HDMI 1 on Dock (below DisplayPort)
# DisplayPort-3: DisplayPort 1 on Dock (single port)
# DisplayPort-4: DisplayPort 2 on Dock (Above HDMI Port)

get_port() {
    # Explanation of this sed script:
    # Part 1:
    #  - Find the line beginning with "DisplayPort-4" (etc.) (/.../{...})
    #  - Strip everything but that port name (s/.../.../)
    #  - Replace the contents of the hold space with that port name (h;)
    # Part 2:
    #  - Find the line containing "EDID:" (/.../{...})
    #  - Load the next line (first line of the EDID) (n;)
    #  - If that next line matches the EDID passed as an argument to this function (/.../{...})
    #     - Replace the pattern space with the contents of the hold space (the port number) (g;)
    #     - Print the pattern space (p;)
    xrandr --prop |
        sed -En \
            -e '/\bconnected\b/{s/^([^ ]+).*/\1/;h};' \
            -e "/[[:blank:]]*EDID:[[:blank:]]*/{n;/${1}/{g;p;};}"

}

get_lid_state() {
    dbus-send --system --print-reply=literal \
        --dest=org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.DBus.Properties.Get \
        string:org.freedesktop.login1.Manager string:LidClosed |
        awk 'NR==1{print $3=="true"?"closed":"open"}'
}

BUILT_IN=$(get_port 00ffffffffffff0006af3d5700000000)
LENOVO_27=$(get_port 00ffffffffffff0030aeaf6147424b32)
LENOVO_32=$(get_port 00ffffffffffff0030aef26100000000)
ASUS_24=$(get_port 00ffffffffffff0006b3c12401010101)

if [ -n "${BUILT_IN}" ]; then
    vrb "BUILT IN: ${BUILT_IN}"
    LID_CLOSED=$(get_lid_state)
    case "${LID_CLOSED}" in
    open)
        vrb "xrandr --output $BUILT_IN --mode 1920x1080 --refresh 60.00 --pos 6400x1080 --rotate normal"
        xrandr --output $BUILT_IN --mode 1920x1080 --refresh 60.00 --pos 6400x1080 --rotate normal
        ;;
    *)
        vrb "xrandr --output $BUILT_IN --off"
        xrandr --output $BUILT_IN --off
        ;;
    esac
else
    err "${RED}Could not find monitor BUILT_IN${RESET}"
fi
if [ -n "${ASUS_24}" ]; then
    vrb "ASUS 24: ${ASUS_24}"
    vrb "xrandr --output $ASUS_24 --mode 1920x1080 --refresh 60.00 --pos 6400x0 --rotate normal"
    xrandr --output $ASUS_24 --mode 1920x1080 --refresh 60.00 --pos 6400x0 --rotate normal
else
    err "${RED}Could not find monitor ASUS_24${RESET}"
fi
if [ -n "${LENOVO_27}" ]; then
    vrb "LENOVO 27: ${LENOVO_27}"
    vrb "xrandr --output $LENOVO_27 --mode 2560x1440 --refresh 60.00 --pos 0x720 --rotate normal"
    xrandr --output $LENOVO_27 --mode 2560x1440 --refresh 60.00 --pos 0x720 --rotate normal
else
    err "${RED}Could not find monitor LENOVO_27${RESET}"
fi
if [ -n "${LENOVO_32}" ]; then
    vrb "LENOVO 32: ${LENOVO_32}"
    vrb "xrandr --output $LENOVO_32 --primary --mode 3840x2160 --refresh 60.00 --pos 2560x0 --rotate normal"
    xrandr --output $LENOVO_32 --primary --mode 3840x2160 --refresh 60.00 --pos 2560x0 --rotate normal
else
    err "${RED}Could not find monitor LENOVO_32${RESET}"
fi

# xrandr \
#     --output eDP --off \
#     --output HDMI-A-0 --off \
#     --output DisplayPort-0 --off \
#     --output DisplayPort-1 --off \
#     --output DisplayPort-2 --mode 1920x1080 --refresh 60.00 --pos 6400x1080 --rotate normal \
#     --output DisplayPort-3 --mode 2560x1440 --refresh 60.00 --pos 0x720 --rotate normal \
#     --output DisplayPort-4 --primary --mode 3840x2160 --refresh 60.00 --pos 2560x0 --rotate normal
