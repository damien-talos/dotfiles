#!/bin/bash
# ------------------------------------------------ #
# Set current screen layout to my preferred layout #
# ------------------------------------------------ #

set -eo pipefail

# Get command info
CMD="$0"
RED='\033[01;31m'
RESET='\033[00m'

ansi() { echo -en "\033[${1}m${*:2}\033[0m"; }
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
vrb() { if [ "$VERBOSE" -gt 1 ]; then out "$@"; fi; }
dbg() { if [ "$VERBOSE" -gt 0 ]; then err "$@"; fi; }
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
        VERBOSE=$((VERBOSE + 2)) && shift && vrb "#-INFO: VERBOSE=$VERBOSE"
        if [[ $VERBOSE -gt 2 ]]; then
            # For super verbose logging, enable the tracing flag as well
            set -x
        fi
        ;;
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
LENOVO_27H_10=$(get_port 00ffffffffffff0030aeaf6147424b32)
LENOVO_T32_20=$(get_port 00ffffffffffff0030aef26100000000)
LENOVO_P32_20=$(get_port 00ffffffffffff0030aea26200000000)

if [ -n "${BUILT_IN}" ]; then
    vrb "BUILT IN: ${BUILT_IN}"
    LID_CLOSED=$(get_lid_state)
    case "${LID_CLOSED}" in
    open)
        xrandr --output "$BUILT_IN" --mode 1920x1080 --refresh 60.00 --pos 6400x1080 --rotate normal
        ;;
    *)
        xrandr --output "$BUILT_IN" --off
        ;;
    esac
else
    err "${RED}Could not find monitor BUILT_IN${RESET}"
fi
if [ -n "${LENOVO_27H_10}" ]; then
    vrb "LENOVO P27h-10: ${LENOVO_27H_10}"
    xrandr --output "$LENOVO_27H_10" --mode 2560x1440_50.00 --refresh 49.96 --pos 0x0 --rotate left
else
    err "${RED}Could not find monitor LENOVO_27H_10${RESET}"
fi
if [ -n "${LENOVO_T32_20}" ]; then
    vrb "LENOVO T32p-20: ${LENOVO_T32_20}"
    xrandr --output "$LENOVO_T32_20" --primary --mode 3840x2160 --refresh 50.00 --pos 1440x212 --rotate normal
else
    err "${RED}Could not find monitor LENOVO_T32_20${RESET}"
fi
if [ -n "${LENOVO_P32_20}" ]; then
    vrb "LENOVO P32p-20: ${LENOVO_P32_20}"
    xrandr --output "$LENOVO_P32_20" --mode 3840x2160 --refresh 50.00 --pos 5280x212 --rotate normal
else
    err "${RED}Could not find monitor LENOVO_P32_20${RESET}"
fi

# xrandr \
#     --output eDP --off \
#     --output HDMI-A-0 --off \
#     --output DisplayPort-0 --off \
#     --output DisplayPort-1 --off \
#     --output DisplayPort-2 --mode 1920x1080 --refresh 60.00 --pos 6400x1080 --rotate normal \
#     --output DisplayPort-3 --mode 2560x1440 --refresh 60.00 --pos 0x720 --rotate normal \
#     --output DisplayPort-4 --primary --mode 3840x2160 --refresh 60.00 --pos 2560x0 --rotate normal
