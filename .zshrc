#!/bin/zsh
# shellcheck shell=zsh
autoload -Uz compinit && compinit

unsetopt auto_cd
export cdpath=($HOME/.links) # Allow `cd`ing to links in the links directory
setopt auto_pushd
setopt chase_links
setopt pushd_ignore_dups
setopt inc_append_history
setopt hist_ignore_dups
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt prompt_subst

source_or_err ~/.zsh_aliases

# Functions are split to individual script files for readability
if [ -d ~/.config/zsh/functions.d ]; then
    for i in ~/.config/zsh/functions.d/*.zsh; do
        if [ -r $i ]; then
            source $i
        fi
    done
    unset i
fi

# Load version control information
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git

####################
### PROMPT SETUP ###
####################

# Set FIRST_PROMPT=1 if it currently has no value
# Ensures that we don't try to calculate previous command
# exit code and timings when none exists yet
FIRST_PROMPT=${FIRST_PROMPT:-1}

if [[ "$(date +%s%N)" != *N ]]; then
    function timer_now {
        # Regular unix date command supports %N (milliseconds)
        date +%s%N
    }
elif command -v gdate >/dev/null 2>&1; then
    function timer_now {
        # On macs, we may be able to use gdate
        gdate +%s%N
    }
else
    function timer_now {
        # If we can't fallback to gdate, we'll just fake it - milliseconds will always be zero
        echo $(($(date +'%s * 1000 + %-N / 1000000')))
    }
fi

# Executed before every command
function preexec() {
    if [ -z "$AT_PROMPT" ]; then
        return
    fi
    unset AT_PROMPT
    last_command_start=$(timer_now)
}
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

function precmd() {
    Last_Command=$? # Must come first! - stores the exit code of the last command ran

    # To distinguish between chained commands (e.g. echo 1; echo 2; echo 3)
    # and being called to display the actual prompt - we don't want to reset
    # $timer_start for each command in the chain, even the the DEBUG trap gets
    # called for each of those commands, so `pre_command` checks this variable
    # to see if we are at a prompt or not
    AT_PROMPT=1

    vcs_info

    # Escape code definitions
    # PromptBlue='\[\033[01;34m\]'
    PromptCyan='\[\033[01;36m\]'
    PromptBrownYellow='\[\033[00;33m\]'
    PromptWhite='\[\033[01;37m\]'
    PromptRed='\[\033[01;31m\]'
    PromptGreen='\[\033[01;32m\]'
    PromptReset='\[\033[00m\]'
    PromptFancyX=$'\342\234\227'
    PromptCheckmark=$'\342\234\223'

    if [[ $FIRST_PROMPT -ne 1 ]]; then
        last_command_run_time=$(timer_stop "$last_command_start") # stop the timer for the last command we ran
        unset last_command_start
    # else
    #     set_git_prompt # Initial setup for git prompt, sources the git prompt file and completion scripts one time at startup
    fi

    # First, reset the prompt string (allows us comment out any other lines later and still be consistent)
    PROMPT=''
    # export PROMPT+='%F{red}%*%f @ %F{yellow}%~%f %F{cyan}${vcs_info_msg_0_}%f%b'$'\n''λ '

    # Results of the last command run (exit code + run time)
    if [[ $FIRST_PROMPT -ne 1 ]]; then
        PROMPT+="%F{white}$Last_Command%f " # Add a bright white exit status for the last command
        # If it was successful, print a green check mark. Otherwise, print
        # a red X.
        if [[ $Last_Command == 0 ]]; then
            PROMPT+="%F{green}$PromptCheckmark"
        else
            PROMPT+="%F{red}$PromptFancyX"
        fi
        PROMPT+=" ($last_command_run_time) " # Time to execute last command
    fi

    PROMPT+="%f%F{red}%*%f " # current time (HH:MM:SS) when this prompt was shown
    if [[ -n "$SSH_CLIENT" ]]; then
        PROMPT+="%F{cyan}%M%f "
    fi
    # PROMPT+="$PromptBrownYellow\w"        # current working directory
    PROMPT+="@ %F{yellow}%~%f" # current working directory

    # PROMPT+="$PromptCyan" # change color to cyan
    # GIT_PROMP=$([ "$(type -t __git_ps1)" == function ] && __git_ps1) # bash function
    PROMPT="$PROMPT %F{cyan}${vcs_info_msg_0_}%f"

    # PROMPT="$PROMPT"'\[\033[0m\]' # change color
    PROMPT="$PROMPT"$'\n' # new line
    PROMPT="$PROMPT"'λ '  # prompt: always λ

    # Clear the variable that prevents checking previous command result and timing
    # for the very first command
    FIRST_PROMPT=0
}

# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git*' formats "%{$fg[blue]%}(%b)%{$reset_color%}%m%u%c%{$reset_color%} "

# PROMPT='%n@%m %1~ %#'
# export PROMPT='%? %F{red}%*%f @ %F{yellow}%~%f %F{cyan}${vcs_info_msg_0_}%f'$'\n''λ '

