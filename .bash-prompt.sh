# shellcheck shell=bash
####################
### PROMPT SETUP ###
####################

# Set FIRST_PROMPT=1 if it currently has no value
# Ensures that we don't try to calculate previous command
# exit code and timings when none exists yet
FIRST_PROMPT=${FIRST_PROMPT:-1}

function timer_now {
    date +%s%N
}
# Executed before *every* command
# e.g. echo 1; sleep 2; echo 3
# will execute this 3 times; see `prompt_command`
# for more info about `$AT_PROMPT` variable
function pre_command {
    if [ -z "$AT_PROMPT" ]; then
        return
    fi
    unset AT_PROMPT
    last_command_start=$(timer_now)
}
trap 'pre_command' DEBUG

# Function to convert an elapsed time into a human readable time
# Accepts one parameter - the time to in nano-seconds
function timer_stop {
    declare timer_start=$1
    declare timer_show
    declare delta_us=$((($(timer_now) - timer_start) / 1000))
    declare us=$((delta_us % 1000))
    declare ms=$(((delta_us / 1000) % 1000))
    declare s=$(((delta_us / (1000 * 1000)) % 60))
    declare m=$(((delta_us / (60 * 1000 * 1000)) % 60))
    declare h=$((delta_us / (60 * 60 * 1000 * 1000)))
    # Goal: always show around 3 digits of accuracy
    if ((h > 0)); then
        timer_show=${h}h${m}m
    elif ((m > 0)); then
        timer_show=${m}m${s}s
    elif ((s >= 10)); then
        timer_show=${s}.$((ms / 100))s
    elif ((s > 0)); then
        timer_show=${s}.$(printf %03d $ms)s
    elif ((ms >= 100)); then
        timer_show=${ms}ms
    elif ((ms > 0)); then
        timer_show=${ms}.$((us / 100))ms
    else
        timer_show=${us}us
    fi
    echo "$timer_show"
}

save_history() {
    # Append to the history file immediately
    history -a
}

set_git_prompt() {
    # Called only one time, in set_prompt
    # Git working branch stuff
    # GIT_EXEC_PATH="$(git --exec-path 2>/dev/null)"
    # COMPLETION_PATH="${GIT_EXEC_PATH%/libexec/git-core}"
    # COMPLETION_PATH="${COMPLETION_PATH%/lib/git-core}"
    # COMPLETION_PATH="$COMPLETION_PATH/share/git/completion"
    COMPLETION_PATH="$HOME"

    unset GIT_PS1_SHOWDIRTYSTATE     # don't enable, too slow
    unset GIT_PS1_SHOWUNTRACKEDFILES # don't enable, too slow
    unset GIT_PS1_SHOWUPSTREAM       # don't enable, too slow
    export GIT_PS1_OMITSPARSESTATE=1 # disables another check

    source_or_err "$COMPLETION_PATH/git-completion.bash"
    source_or_err "$COMPLETION_PATH/git-prompt.sh"
}

###
# Get the current terminal column value.
#
# From https://stackoverflow.com/a/52944692
# From https://stackoverflow.com/questions/62038398/bash-clearing-the-last-output-correctly
###
__get_terminal_column() {
    stty echo # ensure that input is being echoed on screen

    local pos

    IFS='[;' read -p $'\e[6n' -d R -a pos -rs || echo "${FUNCNAME[0]} failed with error: $? ; ${pos[*]}"
    #echo "$((${pos[1]} - 1))" # row
    echo "$((pos[2] - 1))" # column
}

set_prompt() {
    # Escape code definitions
    # PromptBlue='\[\e[01;34m\]'
    PromptCyan='\[\e[01;36m\]'
    PromptBrownYellow='\[\e[00;33m\]'
    PromptWhite='\[\e[01;37m\]'
    PromptRed='\[\e[01;31m\]'
    PromptGreen='\[\e[01;32m\]'
    PromptReset='\[\e[00m\]'
    PromptFancyX='\342\234\227'
    PromptCheckmark='\[\342\234\]\223'

    # First, reset the prompt string (allows us comment out any other lines later and still be consistent)
    PS1=''

    # Add a new line if the previous command didn't end with one
    # Note: Uncommenting this *will* break "typeahead" (any text you've typed before the prompt is visible, will disappear)
    # if [ "$(__get_terminal_column)" != 0 ]; then
    #     PS1="\n"
    # fi

    PS1+='\[\033]0;${PWD//[^[:ascii:]]/?}\007\]' # set window title

    # Results of the last command run (exit code + run time)
    if [[ $FIRST_PROMPT -ne 1 ]]; then
        PS1+="$PromptWhite$Last_Command " # Add a bright white exit status for the last command
        # If it was successful, print a green check mark. Otherwise, print
        # a red X.
        if [[ $Last_Command == 0 ]]; then
            PS1+="$PromptGreen$PromptCheckmark"
        else
            PS1+="$PromptRed$PromptFancyX"
        fi
        PS1+=" ($last_command_run_time) " # Time to execute last command
    fi

    PS1+="$PromptRed\t$PromptReset @ " # current time (HH:MM:SS) when this prompt was shown
    PS1+="$PromptBrownYellow\w"        # current working directory

    PS1+="$PromptCyan"   # change color to cyan
    GIT_PS1=$(__git_ps1) # bash function
    PS1="$PS1$GIT_PS1"

    PS1="$PS1"'\[\033[0m\]' # change color
    PS1="$PS1"'\n'          # new line
    PS1="$PS1"'λ '          # prompt: always λ
}
prompt_command() {
    Last_Command=$? # Must come first! - stores the exit code of the last command ran

    # To distinguish between chained commands (e.g. echo 1; echo 2; echo 3)
    # and being called to display the actual prompt - we don't want to reset
    # $timer_start for each command in the chain, even the the DEBUG trap gets
    # called for each of those commands, so `pre_command` checks this variable
    # to see if we are at a prompt or not
    AT_PROMPT=1

    if [[ $FIRST_PROMPT -ne 1 ]]; then
        last_command_run_time=$(timer_stop "$last_command_start") # stop the timer for the last command we ran
        unset last_command_start
    else
        set_git_prompt # Initial setup for git prompt, sources the git prompt file and completion scripts one time at startup
    fi

    set_prompt               # set the actual prompt displayed
    DATE=$(date +"%Y-%m-%d") # Set the current date as a variable
    export DATE

    save_history # Save the history so it is shared across sessions

    # Clear the variable that prevents checking previous command result and timing
    # for the very first command
    FIRST_PROMPT=0
}

# Show the time taken to execute various parts of the prompt_command
show_prompt_timings() {
    declare -n timings # variable reference by name - set to the name of the variable that we want to display
    if [[ $# -gt 0 ]]; then timings="$1"; else timings='prompt_timings'; fi
    for t in "${!timings[@]}"; do
        printf "%-32s %s\n" "$t" "${timings[$t]}"
    done | sort -n
}
PROMPT_COMMAND=prompt_command # Execute prompt_command() every time we show a prompt
