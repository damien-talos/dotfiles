# Replace builtin `cd` command with a custom one that uses `pushd` instead
function _cd {
    # typing just `_cd` will take you home ;)
    if [ "$1" == "" ]; then
        pushd ~ >/dev/null

    # use `_cd -` to visit previous directory
    elif [ "$1" == "-" ]; then
        popd >/dev/null

    # use `_cd -n` to go n directories back in history
    elif [[ "$1" =~ ^-[0-9]+$ ]]; then
        for i in $(seq 1 ${1/-/}); do
            popd >/dev/null
        done

    # use `_cd -- <path>` if your path begins with a dash
    elif [ "$1" == "--" ]; then
        shift
        pushd -- "$@" >/dev/null

    # basic case: move to a dir and add it to history
    else
        pushd "$@" >/dev/null
    fi
    if [[ $PWD/ = ~/.links/* ]]; then
        # We are in a shortcut link; replace with the actual path
        REALPATH=$(realpath $PWD)
        popd >/dev/null
        pushd -- "$REALPATH" >/dev/null
    fi
}
alias cd=_cd
complete -d cd
