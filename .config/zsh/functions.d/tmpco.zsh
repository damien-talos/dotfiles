tmpco() {
    ADD_WORKTREE_ARGS=$@
    DIRNAME=$(echo $1 | sed -e 's/\//_/g')
    git worktree add /tmp/ramdisk/$DIRNAME $ADD_WORKTREE_ARGS || {
        echo -e "${RED}Error adding worktree for '$ADD_WORKTREE_ARGS'${RESET}"
        return 1
    }
    cd /tmp/ramdisk/$DIRNAME
}
