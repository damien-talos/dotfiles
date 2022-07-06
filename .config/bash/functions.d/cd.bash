# copied from bash_completion _cd function
function _cd_complete {
    local cur
    _init_completion || return

    local IFS=$'\n' i j k

    compopt -o filenames

    # Use standard dir completion if no CDPATH or parameter starts with /,
    # ./ or ../
    if [[ ! ${CDPATH:-} || $cur == ?(.)?(.)/* ]]; then
        _filedir -d
        return
    fi

    local -r mark_dirs=$(_rl_enabled mark-directories && echo y)
    local -r mark_symdirs=$(_rl_enabled mark-symlinked-directories && echo y)

    # we have a CDPATH, so loop on its contents
    for i in ${CDPATH//:/$'\n'}; do
        # create an array of matched subdirs
        k=${#COMPREPLY[@]}
        for j in $(compgen -d -- $i/$cur); do
            if [[ ($mark_symdirs && -L $j || $mark_dirs && ! -L $j) && ! -d ${j#"$i/"} ]]; then
                j+="/"
            fi
            COMPREPLY[k++]=${j#"$i/"}
        done
    done

    _filedir -d

    if ((${#COMPREPLY[@]} == 1)); then
        i=${COMPREPLY[0]}
        if [[ $i == "$cur" && $i != "*/" ]]; then
            COMPREPLY[0]="${i}/"
        fi
    fi

    return
}

# Replace builtin `cd` command with a custom one that uses `pushd` instead
function _cd {
    # typing just `_cd` will take you home ;)
    if [ "$1" == "" ]; then
        pushd ~ >/dev/null || return

    # use `_cd -` to visit previous directory
    elif [ "$1" == "-" ]; then
        popd >/dev/null || return

    # use `_cd -n` to go n directories back in history
    elif [[ "$1" =~ ^-[0-9]+$ ]]; then
        for i in $(seq 1 $((${1/-/} - 1))); do
            popd -n >/dev/null
        done
        popd >/dev/null || return
    # use `_cd -- <path>` if your path begins with a dash
    elif [ "$1" == "--" ]; then
        shift
        pushd -- "$@" >/dev/null || return

    # basic case: move to a dir and add it to history
    else
        pushd "$@" >/dev/null || return
    fi
    if [[ $PWD/ = ~/.links/* ]]; then
        # We are in a shortcut link; replace with the actual path
        REALPATH=$(realpath $PWD)
        popd >/dev/null || return
        pushd -- "$REALPATH" >/dev/null || return
    fi
}
alias cd=_cd
complete -F _cd_complete -o nospace cd
