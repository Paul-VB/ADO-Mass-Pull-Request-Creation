#!/bin/bash

#this file contains some handy funtions used in multiple places

#declare some pretty colors
Black="\033[0;30m";
Red="\033[0;31m";
Green="\033[0;32m";
Yellow="\033[0;33m";
Blue="\033[0;34m";
Cyan="\033[0;36m";
Purple="\033[0;35m";
DarkGrey="\033[0;37m";
DarkGrey="\033[1;30m";
LightRed="\033[1;31m";
LightGreen="\033[1;32m";
LightYellow="\033[1;33m";
LightBlue="\033[1;34m";
LightCyan="\033[1;36m";
LightPurple="\033[1;35m";
White="\033[1;37m";
bgBlack="\033[40m";
bgRed="\033[41m";
bgGreen="\033[42m";
bgYellow="\033[43m";
bgBlue="\033[44m";
bgPurple="\033[45m";
bgCyan="\033[46m";
bgDarkGrey="\033[47m";
NoColor="\033[0m";
eraseLine="\033[0K"

#waits for the user to press the any key
function pressAnyKeyToContinue(){
    read -r -p "Press the any key to continue " input
}

#sets the title of the terminal window
function setTerminalTitle(){
    echo -ne "\e]0;${1}\a"
}

#given a variable, return that variable if it is not empty.
#If it is empty, prompt the user to enter it with a custom message
function promptUserForValueIfEmpty(){
    #check if we actually recieved the cli argument
    if [ -z "$1" ];
    then
        read -r -p "$2" result
        echo "$result"
    else
        echo "$1"
    fi 
}

#asks the user a yes or no question
function promptUserForYesOrNo(){
    local prompt
    prompt="$1"
    while true
        do
        read -r -p "$prompt [Y/n]" input
        case $input in
        [yY][eE][sS]|[yY])
            echo "True"
        break
        ;;
        [nN][oO]|[nN])
            echo "False"
        break
        ;;
        *)
            echo "Invalid input..." >&2
        ;;
        esac
    done
}

#get the default branch name of the current repository
function getDefaultBranchName(){
    echo "$(eval "git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'")"
}

#get the current branch name of the current repository
function getCurrentBranchName(){
    echo "$(eval "git symbolic-ref HEAD | sed 's@^refs/heads/@@'")"
}