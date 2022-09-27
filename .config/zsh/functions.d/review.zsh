review() {
    OUTPUT=$(~/bin/review --echo-cd "$@" | tee /dev/tty | tail -n 1)
    if [[ $? -eq 0 ]] && [[ -n "$OUTPUT" ]] && [[ -d "$OUTPUT" ]]; then
        cd "$OUTPUT" || return 0
        return 0
    else
        return $?
    fi
}

unreview() {
    local PULL_REQUEST_ID=$1
    local CHECKOUT_PATH=/tmp/ramdisk/pr$PULL_REQUEST_ID
    local GIT_ROOT=~/workspace/talos/Ava-UI
    if [[ -d $CHECKOUT_PATH ]]; then
        if [[ "$(pwd)" == "$CHECKOUT_PATH" ]]; then
            cd $GIT_ROOT
        fi
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
