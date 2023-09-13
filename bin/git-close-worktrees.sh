#!/bin/bash

urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for ((pos = 0; pos < strlen; pos++)); do
        c=${string:$pos:1}
        case "$c" in
        [-_.~a-zA-Z0-9]) o="${c}" ;;
        *) printf -v o '%%%02x' "'$c" ;;
        esac
        encoded+="${o}"
    done
    echo "${encoded}"  # You can either set a return variable (FASTER)
    REPLY="${encoded}" #+or echo the result (EASIER)... or both... :p
}

git worktree list --porcelain | grep worktree | sed -e 's/worktree //' | while IFS= read -r worktree; do
    printf "Worktree: ${worktree}\n"
    WORKTREE_BRANCH=$(git -C "${worktree}" rev-parse --abbrev-ref HEAD)
    PULL_REQUEST_ID=$(echo "${worktree}" | sed -e 's/.*pr\([[:digit:]]\)/\1/p;d')
    if [ -z "${PULL_REQUEST_ID}" ]; then
        GITHUB_RESPONSE=$(curl -s \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            https://api.github.com/search/issues?q=is%3Apr%20repo%3Atalostrading%2FAva-UI%20head%3A$(urlencode $WORKTREE_BRANCH))
        PULL_REQUEST_ID=$(printf "%s" "$GITHUB_RESPONSE" | jq -r .items[0].number)
    fi
    if [ ! -z "${PULL_REQUEST_ID}" ]; then
        GITHUB_RESPONSE=$(curl -s \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            https://api.github.com/repos/talostrading/Ava-UI/pulls/$PULL_REQUEST_ID)
        PR_STATUS=$(printf "%s" "$GITHUB_RESPONSE" | jq -r .state)
        PR_BRANCH=$(printf "%s" "$GITHUB_RESPONSE" | jq -r .head.ref)
        printf " - PR: ${PULL_REQUEST_ID}\n"
        printf " - PR Status: ${PR_STATUS}\n"
        printf " - PR Branch: ${PR_BRANCH}\n"
    # else
    #     GITHUB_RESPONSE=$(curl -s \
    #         -H "Authorization: token $GITHUB_TOKEN" \
    #         -H "Accept: application/vnd.github.v3+json" \
    #         https://api.github.com/repos/talostrading/Ava-UI/branches/$WORKTREE_BRANCH)
    #     PR_STATUS=$(printf "%s" "$GITHUB_RESPONSE" | jq -r .state)
    #     printf " - PR: ${PULL_REQUEST_ID}\n"
    #     printf " - PR Status: ${PR_STATUS}\n"

    fi
done
