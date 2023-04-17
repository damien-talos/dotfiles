#!/bin/bash
#=------------------------------------------------ #
# Generate interesting statistics about a git repo #
#=------------------------------------------------ #

set -o pipefail

# Get command info
CMD_PWD=$(pwd)
CMD="$0"
CMD_DIR="$(cd "$(dirname "$CMD")" && pwd -P)"
RED="\033[01;31m"
DEFAULT_VAR_VALUE="\033[2m\033[3m"
RESET="\033[00m"

# BEGIN SCRIPT VARIABLES
[ -n "$VERBOSE" ] || VERBOSE=0
[ -n "$CALC_NET_LINE_CHANGE" ] || CALC_NET_LINE_CHANGE=0
[ -n "$CALC_TOTAL_OWNERSHIP" ] || CALC_TOTAL_OWNERSHIP=0
[ -n "$GIT_FROM" ] || GIT_FROM=""
[ -n "$GIT_TO" ] || GIT_TO="HEAD"
# END SCRIPT VARIABLES

set -u

out() { echo -e "$(date +%Y-%m-%dT%H:%M:%SZ): $*"; }
err() { out "$*" 1>&2; }
vrb() { if [ $VERBOSE -gt 1 ]; then out "$@"; fi; }
dbg() { if [ $VERBOSE -gt 0 ]; then err "$@"; fi; }
die() { err "EXIT: ${RED}$1${RESET}" && [ "$2" ] && [ "$2" -ge 0 ] && exit "$2" || exit 1; }
value() { echo -e "${DEFAULT_VAR_VALUE}$1${RESET}"; }

# Show help function to be used below
show_help() {
    awk 'NR>1{print} /^(###|$)/{exit}' "$CMD"
    echo "USAGE: $(basename "$CMD") [arguments]"
    echo "ARGS:"
    AWK_SCRIPT_1=$(
        cat - <<'_EOF_'
{
    short[NR] = $1
    long[NR] = $2
    desc[NR] = $3
}

END {
    maxShort = 0
    maxLong = 0
    maxDesc = 0

    for (i = 0; i <= NR; i++) {
        if (length(short[i]) > maxShort) { maxShort = length(short[i]) }

        if (length(long[i]) > maxLong) { maxLong = length(long[i]) }

        if (length(desc[i]) > maxDesc) { maxDesc = length(desc[i]) }
    }

    for (i = 0; i <= NR; i++) { printf("%-*s%-*s\t%s\n", maxShort+2, short[i], maxLong+2, long[i], desc[i]) }
}

_EOF_
    )
    MSG=$(awk '/# BEGIN SWITCHES/,/# END SWITCHES/' "$CMD" | sed -e '/^[[:space:]]*-.*)/!d; s/^[[:space:]]*\(-.*)\)/\1/; s/(DEFAULT: \(.*\))$/(DEFAULT: $(value "\1"))/g; s/^[[:space:]]*\(-[[:alpha:]]\)\?[[:space:]|]*\(--[^)]\+\))[[:space:]#]*\(.*\)$/\1\t\2\t\3/g;' | awk -F '\t' "$AWK_SCRIPT_1")
    EMSG=$(eval "echo -e \"$MSG\"")
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
while [ "$#" -gt 0 ]; do
    # NARGS=$#
    case $1 in
    # BEGIN SWITCHES
    -h | --help) # Show this help message
        show_help
        exit 0
        ;;
    -v | --verbose) # Enable verbose messages (DEFAULT: $VERBOSE)
        VERBOSE=$((VERBOSE + 1)) && shift && vrb "#-INFO: VERBOSE=$VERBOSE"
        if [[ $VERBOSE -gt 2 ]]; then
            # For super verbose logging, enable the tracing flag as well
            set -x
        fi
        ;;
    -c | --calc-net-line-change) # Calculate net line changes (DEFAULT: $CALC_NET_LINE_CHANGE)
        CALC_NET_LINE_CHANGE=1 && shift && vrb "#-INFO: CALC_NET_LINE_CHANGE=$CALC_NET_LINE_CHANGE" ;;
    -o | --calc-total-ownership) # Calculate total ownership (DEFAULT: $CALC_TOTAL_OWNERSHIP)
        CALC_TOTAL_OWNERSHIP=1 && shift && vrb "#-INFO: CALC_TOTAL_OWNERSHIP=$CALC_TOTAL_OWNERSHIP" ;;
    --from) # Git reference to start calculations from (DEFAULT: \$(git rev-list --max-parents=0 HEAD))
        shift && GIT_FROM=$1 && shift && vrb "#-INFO: GIT_FROM=$GIT_FROM" ;;
    --to) # Git reference to end calculations at (DEFAULT: $GIT_TO)
        shift && GIT_TO=$1 && shift && vrb "#-INFO: GIT_TO=$GIT_TO" ;;
    *) # unknown option
        if (echo "$1" | grep -qE -e '^-[[:alpha:]]{2,}$'); then
            # Likely multiple single-character flags combined
            # Split them into individual args instead
            new_args=($(echo "$1" | grep -o '[[:alnum:]]' | sed -E -e 's/^/-/'))
            # Remove the current arg
            shift
            # Prepend the multiple new args into our args array
            set -- "${new_args[@]}" "$@"
        elif (echo "$1" | grep -qE -e '^--[^[:space:]]+=.*'); then
            # Likely an arg passed as `--arg=value` instead of `--arg value`
            # Split into 2 separate args
            new_args=($(echo "$1" | sed -E -e 's/=/\n/g;'))
            # Remove the current arg
            shift
            # Prepend the multiple new args into our args array
            set -- "${new_args[@]}" "$@"
        else
            dbg "Unknown option: $1"
            show_help
            exit 1
        fi
        ;;
        # END SWITCHES
    esac
done

# Enable errexit
set -e

if [[ -z "$GIT_FROM" ]]; then
    dbg "Default GIT_FROM to first commit"
    GIT_FROM=$(git rev-list --max-parents=0 HEAD)
fi

if [ $VERBOSE -gt 0 ]; then
    show_variables
fi

if [[ $CALC_NET_LINE_CHANGE == 1 ]]; then
    SED_SCRIPT_IGNORE_PATHS=$(
        find . -maxdepth 1 -name '*ignore' | xargs sed -e 's/#.*$//g; /./!d; /^!/d; s/\./\\./g; s/\*\*/.*/g; s/\*/[^*]\+/g; s/\//\\\//g; s/.*/\/\0\/d;/g'
        cat - <<'_EOF_'
/^[ \t]*$/d;
/^-\t-/d;
/.*\.(svg|json)$/d;
_EOF_
    )
    AWK_SCRIPT_1=$(
        cat - <<'_EOF_'
{
    if ($0 ~ /^[[:digit:]]+/) {
        sub(/[[:space:]]*/, "", $0)
        split($0, stats, /[^[:digit:]]+/)
        printf("%s|%d|%d|%d\n", author, 1, stats[1], stats[2])
    }
    else { author = $0 }
}
_EOF_
    )
    AWK_SCRIPT_SUMMARIZE_STATS=$(
        cat - <<'_EOF_'
{
    author = sprintf("%s %s", $1, $2)

    if (!author in files) { files[author] = 0 }
    files[author] += $3

    if (!author in added) { added[author] = 0 }
    added[author] += $4

    if (!author in deleted) { deleted[author] = 0 }
    deleted[author] += $5
}

END {
    for (author in files) {
        printf(\
            "%s|%d|%d|%d|%d\n",
            author,
            files[author],
            added[author],
            deleted[author],
            added[author] - deleted[author]\
        )
    }
}
_EOF_
    )
    echo "Net line change per author from $GIT_FROM to $GIT_TO"
    (
        printf "Author|Files modified|Added lines|Deleted lines|Net lines\n"
        git log --oneline --no-merges --pretty=format:"%aN|<%aE>" --numstat "$GIT_FROM..$GIT_TO" |
            sed -E "$SED_SCRIPT_IGNORE_PATHS" |
            awk "$AWK_SCRIPT_1" |
            awk -F"|" "$AWK_SCRIPT_SUMMARIZE_STATS" |
            sort -t "|" --key=5n
    ) |
        column -t -s "|"
fi

if [[ $CALC_TOTAL_OWNERSHIP == 1 ]]; then
    echo "Total lines ownership across entire repo"
    (
        printf "Author|Lines owned|Percentage lines owned\n"
        LC_ALL=C git ls-files |
            sed -E '/.*\.(svg|json)$/d; /packages\/(charting_library|tradingview|datafeeds)/d; /^out\//d; /apps\/\w+\/public/d; /packages\/kyoko\/src\/types\/types.ts/d; /\/build\//d; /packages\/shared\/dist\//d;' |
            xargs -I{} git blame --line-porcelain {} |
            sed -n '/^author /{ h; }; /^author-mail /{ x; G; s/\n/ /g;s/author\(-mail\)\? //g; p; }' |
            awk 'BEGIN {total=0;} {total += 1; authors[$0] += 1; } END { for (author in authors) { cmd = sprintf("git check-mailmap \"%s\"", author); cmd | getline authorIdent; close(cmd) ; printf("%s|%d|%.2f%%\n", authorIdent, authors[author], authors[author] / total * 100); } printf("Total lines|%d|100%%\n", total); }' |
            sort -t "|" --key=2n
    ) |
        column -t -s "|"
fi
# # exec $(sed -E '/^\s+#.*/d; $!{ H; d; }; x; G; p' << command
# sed -n -E '/^[[:space:]]+#.*/d; $!{ H; d; }; x; G; p' << command
# (printf "Author|Lines owned|Percentage lines owned\n";
#     # list files not ignore by git
#     git ls-files |
#         # ignore other files that are irrelevant
#         sed -E '/.*\.(svg|json)$/d; /packages\/(charting_library|tradingview|datafeeds)/d; /^out\//d; /apps\/\w+\/public/d; /packages\/kyoko\/src\/types\/types.ts/d; /\/build\//d; /packages\/shared\/dist\//d;' |
#         # run each file through git blame
#         xargs -I{} git blame --line-porcelain {} |
#         # Parse the output of git-blame; concat the author and author-mail lines, and only output those
#         sed -n '/^author /{ h; }; /^author-mail /{ x; G; s/\n/ /g;s/author\(-mail\)\? //g; p; }' |
#         # For each line we see (format: "author name <author email>") increment both the total line count and that author's line count, then print the totals when done
#         awk 'BEGIN {total=0;} {total += 1; authors[$0] += 1; } END { for (author in authors) { cmd = sprintf("git check-mailmap \"%s\"", author); cmd | getline authorIdent; close(cmd) ; printf("%s|%d|%.2f%%\n", authorIdent, authors[author], authors[author] / total * 100); } printf("Total lines|%d|100%%\n", total); }' |
#         # sort all lines by the 3 column (percentage owned)
#         sort -t "|" --key=2n;
#     ) |
#     # display in a nice table format
#     column -t -s "|";
# command | sh
# echo $command

# (set -x; (printf "Author|Lines owned|Percentage lines owned\n";

#     git ls-files | #list files not ignore by git
#         sed -E '/.*\.(svg|json)$/d; /packages\/(charting_library|tradingview|datafeeds)/d; /^out\//d; /apps\/\w+\/public/d; /packages\/kyoko\/src\/types\/types.ts/d; /\/build\//d; /packages\/shared\/dist\//d;' # ignore other files that are irrelevant
#     ) | head -n 20
#     | column -t -s "|"; set +x)# display in a nice table format

#         | xargs -I{} git blame --line-porcelain {} # run each file through git blame
#         # Parse the output of git-blame; concat the author and author-mail lines, and only output those
#         sed -n '/^author /{ h; }; /^author-mail /{ x; G; s/\n/ /g;s/author\(-mail\)\? //g; p; }' |
#         # For each line we see (format: "author name <author email>") increment both the total line count and that author's line count, then print the totals when done
#         awk 'BEGIN {total=0;} {total += 1; authors[$0] += 1; } END { for (author in authors) { cmd = sprintf("git check-mailmap \"%s\"", author); cmd | getline authorIdent; close(cmd) ; printf("%s|%d|%.2f%%\n", authorIdent, authors[author], authors[author] / total * 100); } printf("Total lines|%d|100%%\n", total); }' |
#         # sort all lines by the 3 column (percentage owned)
#         sort -t "|" --key=2n;

# (printf "Author|Lines owned|Percentage lines owned\n"; \
#     git ls-files | \
#         sed -E '/.*\.(svg|json)$/d; /packages\/(charting_library|tradingview|datafeeds)/d; /^out\//d; /apps\/\w+\/public/d; /packages\/kyoko\/src\/types\/types.ts/d; /\/build\//d; /packages\/shared\/dist\//d;' | \
#         xargs -I{} git blame --line-porcelain {} | \
#         sed -n '/^author /{ h; }; /^author-mail /{ x; G; s/\n/ /g;s/author\(-mail\)\? //g; p; }' | \
#         awk 'BEGIN {total=0;} {total += 1; authors[$0] += 1; } END { for (author in authors) { cmd = sprintf("git check-mailmap \"%s\"", author); cmd | getline authorIdent; close(cmd) ; printf("%s|%d|%.2f%%\n", authorIdent, authors[author], authors[author] / total * 100); } printf("Total lines|%d|100%%\n", total); }' | \
#         sort -t "|" --key=2n; \
#     ) | \
#     column -t -s "|";
