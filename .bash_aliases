# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias resource='source ~/.bashrc'
alias edrc='$EDITOR ~/.bashrc'

alias portforward='gsudo powershell.exe -File "c:/users/Damien/workspace/talos/network.ps1"'

alias ls='lsd'
alias la='ls --color=auto -alF'
alias ll='la'

alias current-paths='echo $PATH | awk -F : '"'"'BEGIN {OFS="\n"}; {$1=$1; print $0}'"'"

alias dirs='dirs -v'

alias temp-chrome="~/.local/share/flatpak/exports/bin/org.chromium.Chromium --temp-profile --user-data-dir=/tmp/${RANDOM}"

. ~/.talos_aliases

alias lspath="which \$(compgen -A function -abck) | sort -u"
