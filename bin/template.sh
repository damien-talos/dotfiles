#!/bin/bash
# --------------------------------------------- #
# SCRIPT DESCRIPTION GOES HERE #
# --------------------------------------------- #

# Get command info
CMD_PWD=$(pwd)
CMD="$0"
CMD_DIR="$(cd "$(dirname "$CMD")" && pwd -P)"
RED='\033[01;31m'
RESET='\033[00m'

# BEGIN SCRIPT VARIABLES
[ -n "$VERBOSE" ] || VERBOSE=0
[ -n "$OPEN_EDITOR" ] || OPEN_EDITOR=1
[ -n "$YARN_INSTALL" ] || YARN_INSTALL=1
[ -n "$PULL_REQUEST_ID" ] || PULL_REQUEST_ID=
[ -n "$BRANCH_NAME" ] || BRANCH_NAME=""
[ -n "$CHECKOUT_PATH" ] || CHECKOUT_PATH=""
[ -n "$GIT_WORKTREE_ROOT" ] || GIT_WORKTREE_ROOT="~/workspace/talos/Ava-UI"
[ -n "$ECHO_CURRENT_DIR" ] || ECHO_CURRENT_DIR=0
# END SCRIPT VARIABLES

out() { echo -e "$(date +%Y-%m-%dT%H:%M:%SZ): $*"; }
err() { out "$*" 1>&2; }
vrb() { if [ $VERBOSE -gt 1 ]; then out "$@"; fi; }
dbg() { if [ $VERBOSE -gt 0 ]; then err "$@"; fi; }
die() { err "EXIT: ${RED}$1${RESET}" && [ "$2" ] && [ "$2" -ge 0 ] && exit "$2" || exit 1; }

# Show help function to be used below
show_help() {
    awk 'NR>1{print} /^(###|$)/{exit}' "$CMD"
    echo "review checks out a git worktree into the ramdisk"
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
    -e | --edit) # Open editor after checkout (DEFAULT: $OPEN_EDITOR)
        shift && OPEN_EDITOR=1 && vrb "#-INFO: OPEN_EDITOR=$OPEN_EDITOR" ;;
    -ne | --no-edit) # Don't open editor after checkout (DEFAULT: $((1-OPEN_EDITOR)))
        shift && OPEN_EDITOR=0 && vrb "#-INFO: OPEN_EDITOR:$OPEN_EDITOR" ;;
    -i | --install) # Run "yarn install" after checkout (DEFAULT: $YARN_INSTALL)
        shift && YARN_INSTALL=1 && vrb "#-INFO: YARN_INSTALL=$YARN_INSTALL" ;;
    -ni | --no-install) # Don't run "yarn install" after checkout (DEFAULT: $((1-YARN_INSTALL)))
        shift && YARN_INSTALL=0 && vrb "#-INFO: YARN_INSTALL=$YARN_INSTALL" ;;
    -pr | --pull-request-id) # Pull Request ID to checkout (DEFAULT: $PULL_REQUEST_ID)
        shift && PULL_REQUEST_ID="$1" && shift && vrb "#-INFO: PULL_REQUEST_ID=$PULL_REQUEST_ID" ;;
    -br | --branch) # Name of branch to checkout (if not specified, will be the branch for the specified pull request) (DEFAULT: $BRANCH_NAME)
        shift && BRANCH_NAME="$1" && shift && vrb "#-INFO: BRANCH_NAME=$BRANCH_NAME" ;;
    -path | --checkout-path) # Path to checkout into (DEFAULT: ${CHECKOUT_PATH:-/tmp/ramdisk/pr\$PULL_REQUEST_ID})
        shift && CHECKOUT_PATH="$1" && shift && vrb "#-INFO: CHECKOUT_PATH=$CHECKOUT_PATH" ;;
    -root | --git-worktree-root) # Main git path (DEFAULT: ${GIT_WORKTREE_ROOT:-~/workspace/talos/Ava-UI})
        shift && GIT_WORKTREE_ROOT="$1" && shift && vrb "#-INFO: GIT_WORKTREE_ROOT=$GIT_WORKTREE_ROOT" ;;
    -ecd | --echo-cd) # Echo the CWD before exit (to allow calling function to cd / source) (DEFAULT: $ECHO_CURRENT_DIR)
        shift && ECHO_CURRENT_DIR=1 && vrb "#-INFO: ECHO_CURRENT_DIR=$ECHO_CURRENT_DIR" ;;
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

PULL_REQUEST_ID="${PULL_REQUEST_ID:-$1}"
CHECKOUT_PATH=$(realpath "${CHECKOUT_PATH:-/tmp/ramdisk/pr$PULL_REQUEST_ID}")
GIT_WORKTREE_ROOT=$(realpath "${GIT_WORKTREE_ROOT}")
if [ -z "$BRANCH_NAME" ] && [ -n "$PULL_REQUEST_ID" ]; then
    dbg "BRANCH_NAME not set, evaluating based on PULL_REQUEST_ID=$PULL_REQUEST_ID"
    BRANCH_NAME=$(curl -s \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/repos/talostrading/Ava-UI/pulls/$PULL_REQUEST_ID |
        jq -r .head.ref)
    if [ $? -ne 0 ]; then
        die "Error retrieving branch name from github" 1
    fi
fi

if [ $VERBOSE -gt 0 ]; then
    show_variables
fi

if [ -z "$PULL_REQUEST_ID" ] && [ -z "$BRANCH_NAME" ]; then
    show_help
    die "Either BRANCH_NAME or PULL_REQUEST_ID must be set"
fi

if [ -d "${CHECKOUT_PATH}" ]; then
    dbg "${CHECKOUT_PATH} exists"
    cd "${CHECKOUT_PATH}"

    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD) || die "Error getting current branch name in ${CHECKOUT_PATH}" $?
    dbg "Current branch = ${CURRENT_BRANCH}"

    if [ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]; then
        git -C "${GIT_WORKTREE_ROOT}" fetch -p -P --all --tags || die "Error syncing repo" $?
        git switch $BRANCH_NAME || die "Error switching from $CURRENT_BRANCH to $BRANCH_NAME" $?
    fi
    git pull --ff-only || die "Error pulling latest changes for $BRANCH_NAME" $?
else
    git -C "${GIT_WORKTREE_ROOT}" fetch -p -P --all --tags || die "Error syncing repo" $?
    git -C "${GIT_WORKTREE_ROOT}" worktree add "${CHECKOUT_PATH}" $BRANCH_NAME || die "Error adding worktree for PR$PULL_REQUEST_ID ($BRANCH_NAME)" $?
fi
[[ $OPEN_EDITOR == 1 ]] && code "${CHECKOUT_PATH}"
[[ $YARN_INSTALL == 1 ]] && yarn install --cwd "${CHECKOUT_PATH}"
[[ $ECHO_CURRENT_DIR == 1 ]] && echo $(realpath -L -P "${CHECKOUT_PATH}")
exit 0
