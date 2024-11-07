#!/bin/bash
# --------------------------------------------- #
# SCRIPT DESCRIPTION GOES HERE #
# --------------------------------------------- #

set -o pipefail

# Get command info
# CMD_PWD=$(pwd)
CMD="$0"
# CMD_DIR="$(cd "$(dirname "$CMD")" && pwd -P)"

# Escape code definitions
BLINK='\033[5m'
UNBLINK='\033[25m'
BOLD='\033[1m'
UNBOLD='\033[22m'
BLUE='\033[01;34m'
CYAN='\033[01;36m'
DIM='\033[2m'
UNDIM='\033[22m'
GRAY='\033[0;30m'
GREEN='\033[01;32m'
RED='\033[01;31m'
STRIKETRHOUGH='\033[9m'
UNSTRIKETHROUGH='\033[29m'
RESET="\033[00m"
UNDERLINE='\033[4m'
UNUNDERLINE='\033[24m'
WHITE='\033[01;37m'

# BEGIN SCRIPT VARIABLES
[ -n "$VERBOSE" ] || VERBOSE=0
# END SCRIPT VARIABLES

out() { echo -e "$(date +%Y-%m-%dT%H:%M:%SZ): $*"; }
err() { out "$*" 1>&2; }
vrb() { if [ "$VERBOSE" -gt 1 ]; then out "$@"; fi; }
dbg() { if [ "$VERBOSE" -gt 0 ]; then err "$@"; fi; }
die() { err "EXIT: ${RED}$1${RESET}" && [ "$2" ] && [ "$2" -ge 0 ] && exit "$2" || exit 1; }

# Show help function to be used below
# This function reads the source of this shell file, and extracts the help text
# Help text is found between the `# BEGIN SWITCHES` and `# END SWITCHES` comments
# Arbitrary text can be added to the help text by adding a line starting with `## `
show_help() {
    awk 'NR>1{print} /^(###|$)/{exit}' "$CMD"
    echo "review checks out a git worktree into the ramdisk"
    echo "USAGE: $(basename "$CMD") [arguments] [pull request id]"
    echo "ARGS:"
    MSG=$(
        awk '/# BEGIN SWITCHES/,/# END SWITCHES/' "$CMD" | sed -e 's/^[[:space:]]*//' -E -e 's/(\|([^)]+))?\)/\t\2\t/' | awk -F'\t' -f <(
            cat - <<'EOD'
BEGIN {
	n=1;
	max[1]=max[2]=0;
}
function maxes(a,b){
	if(length(a)>max[1])max[1]=length(a);if(length(b)>max[2])max[2]=length(b);
}
/^-/ {
	sub(/^[[:space:]]*#[[:space:]]/,"", $3);
    gsub(/^[[:space:]]+|[[:space:]]+$/,"",$1);
    gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2);
	lines[n,1]="VAR";
	maxes($1, $2);
	lines[n,2]=$1;
	lines[n,3]=$2;
	lines[n,4]=$3;
	n++;
}
/^##/ {
	lines[n,2]=substr($1, 3);
	n++;
}
END{
	for(i=1;i<n;i++) {
		if (lines[i,1]=="VAR") {
			printf "  %-*s%-*s%s\n", max[1]+2, lines[i,2], max[2]+2, lines[i,3],lines[i,4];
		} else {
			print lines[i,2];
		}
	}
}
EOD
        )
    )
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
    # -pr | --pull-request-id) # Pull Request ID to checkout (DEFAULT: $PULL_REQUEST_ID)
    #     shift && PULL_REQUEST_ID="$1" && shift && vrb "#-INFO: PULL_REQUEST_ID=$PULL_REQUEST_ID" ;;

    -h | --help) # Show this help message
        show_help
        exit 0
        ;;
    -v | --verbose) # Increase verbosity (repeat for higher level) (DEFAULT: $VERBOSE)
        shift && VERBOSE=$((VERBOSE + 1)) && vrb "#-INFO: VERBOSE=$VERBOSE" ;;
    # Would be nice to treat these as the equivalent of -vv, -vvv, etc but that's a bit more complex
    # This is a good enough solution for now
    -vv) # Increase verbosity to "verbose" level
        shift && VERBOSE=$((VERBOSE + 2)) && vrb "#-INFO: VERBOSE=$VERBOSE"
        ;;
    -vvv) # Increase verbosity to "trace" level
        shift && VERBOSE=$((VERBOSE + 3)) && vrb "#-INFO: VERBOSE=$VERBOSE"
        ;;
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

if [[ $VERBOSE -gt 2 ]]; then
    set -x
fi

set -e

set -- "${POSITIONAL[@]}"

# After potentially processing extra args to set variables, show the variables
if [ $VERBOSE -gt 0 ]; then
    show_variables
fi

out "TEST: ${BLUE}TESTING ${BOLD}GRAY ${STRIKETRHOUGH}TEXT${RESET}"

exit 0
