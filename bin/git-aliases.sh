#!/bin/sh


git config --get-regexp '^alias\.' | # get all aliases
    sed -E 's/alias\.([[:alnum:]-]+).*/\1/' | # extract alias names
    sort | # sort aliases
    xargs -I'{}' sh -c "grep -B1 -e '^\s\+{}\s*=' \$(git config --show-origin 'alias.{}' | awk -F'[:[:space:]]' '{print \$2}')" - {} | # Find the file the alias was defined in, search that file, and display the line that defines the alias & the line preceding that definition
    awk '!(NR%2){alias=$0;gsub(/^[[:space:]]*[[:alnum:]-]+[[:space:]]*=[[:space:]]*/,"",alias);gsub(/\\033/,"\033",p);print$0(p==""?"    ### \033[3m\033[2m"alias"\033[0m":p)}{($0 ~ /###/?p=$0:p="")}' | # Format the output ... if the line is even, store the alias name, remove the alias name from the line, replace \033 with the escape character, print the line, and if the previous line is empty, print the alias name in red. If the line is odd, store the line if it contains "###", so we can use it as the description.
    sed -re 's/( =)(.*)(###)/:*/g' |
    awk -F '*' '{printf "\033[1;31m%-30s\033[0m %s\n", $1, $2}' |
    sort
