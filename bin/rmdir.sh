#!/bin/bash
# --------------------------------------------- #
# Fast async removal of a directory             #
# --------------------------------------------- #

# Get command info
CMD_PWD=$(pwd)
CMD="$0"
# CMD_DIR="$(cd "$(dirname "$CMD")" && pwd -P)"
RED='\033[01;31m'
RESET='\033[00m'

# asynchronously remove a directory, much faster than a synchronous remove
# works by first moving the folders to delete into a temporary dir (which is a fast operation),
# then deleting that temporary dir in a background task
rmdir() {
    declare TMPDIR=${TEMP:-/tmp}/~$RANDOM
    while [ -d "$TMPDIR" ]; do
        TMPDIR=${TEMP:-/tmp}/~$RANDOM
    done

    local returnCode=0

    for target in $@; do
        if [ $# -gt 1 ]; then
            # Show name of the directory currently being deleted, when we are deleting > 1
            echo "${FUNCNAME[0]} $target"
        fi
        if [ ! -e "$target" ]; then
            echo -e "${RED}$target does not exist${RESET}"
            returnCode=2
            break
        elif [ -L "$target" ]; then
            # If the target is a link, just remove the link itself
            rm "$target"
        else
            if [ ! -d "$TMPDIR" ]; then
                # Make the temp dir if it doesn't yet exist
                mkdir -p $TMPDIR
            fi
            # In case we are moving dirs with the same name, find a unique target dir nae
            declare TMPDIR_TARGET=$TMPDIR/${target##*/}
            while [ -d "$TMPDIR_TARGET" ]; do
                TMPDIR_TARGET=$TMPDIR/${target##*/}~$RANDOM
            done
            # Use cmd for the move because it seems to fail less often
            mv "${target%/}" "$TMPDIR_TARGET" >/dev/null
        fi
        if [ -e "$target" ]; then
            echo -e "${RED}Unable to delete $target - is something in this list locking it?${RESET}"
            # locks $target
            returnCode=1
        fi
    done
    if [ -e "$TMPDIR" ]; then
        if [ "$(ls -A "$TMPDIR")" ]; then
            # temp dir is not empty, delete asynchronously
            rm -rf "$TMPDIR" &>/dev/null &
        else
            # temp dir is empty, just delete it immediately
            rm -rf "$TMPDIR" &>/dev/null
        fi
    fi
    return $returnCode
}


if [[ "$0" == "$BASH_SOURCE" ]]; then
    # Script was run as a command
    rmdir $*
fi
