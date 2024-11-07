review() {
    OUTPUT=$(
        set -o pipefail
        ~/bin/review --echo-cd "$@" | tee /dev/tty | tail -n 1
    )
    if [[ $? -eq 0 ]] && [[ -n "$OUTPUT" ]] && [[ -d "$OUTPUT" ]]; then
        # cd into the dir we just checked out
        cd "$OUTPUT" || return 0
        return 0
    else
        return $?
    fi
}

unreview() {
    local PULL_REQUEST_ID=$1
    local CHECKOUT_PATH=~/workspace/talos/avatrees/pr$PULL_REQUEST_ID
    local GIT_ROOT=~/workspace/talos/Ava-UI
    if [[ -d $CHECKOUT_PATH ]]; then
        if [[ "$(pwd)" == "$CHECKOUT_PATH" ]]; then
            cd $GIT_ROOT
        fi
        # Delete the directory first using `rmdir`, which is almost instantaneous
        rmdir $CHECKOUT_PATH || {
            echo -e "${RED}Error removing directory $CHECKOUT_PATH${RESET}"
            return 1
        }

    fi
    if git -C $GIT_ROOT worktree list --porcelain | grep -e "worktree $CHECKOUT_PATH"; then
        # Cleanup the git worktree from the index
        git -C $GIT_ROOT worktree remove $CHECKOUT_PATH || {
            echo -e "${RED}Error removing worktree for PR $PULL_REQUEST_ID${RESET}"
            return 1
        }
    fi
    return 0
}

work-on() {
    GIT_WORKTREE_ROOT=~/workspace/talos/avatrees/
    OUTPUT=$(GIT_WORKTREE_ROOT="${GIT_WORKTREE_ROOT}" ~/bin/review --echo-cd "$@" | tee /dev/tty | tail -n 1)
    if [[ $? -eq 0 ]] && [[ -n "$OUTPUT" ]] && [[ -d "$OUTPUT" ]]; then
        cd "$OUTPUT" || return 0
        return 0
    else
        return $?
    fi
}

# unreview() {
#     local PULL_REQUEST_ID=$1
#     local CHECKOUT_PATH=/tmp/ramdisk/pr$PULL_REQUEST_ID
#     local GIT_ROOT=~/workspace/talos/Ava-UI
#     if [[ -d $CHECKOUT_PATH ]]; then
#         if [[ "$(pwd)" == "$CHECKOUT_PATH" ]]; then
#             cd $GIT_ROOT
#         fi
#         git -C $GIT_ROOT worktree remove $CHECKOUT_PATH || {
#             echo -e "${RED}Error removing worktree for PR $PULL_REQUEST_ID${RESET}"
#             return 1
#         }
#     fi
#     return 0
# }
