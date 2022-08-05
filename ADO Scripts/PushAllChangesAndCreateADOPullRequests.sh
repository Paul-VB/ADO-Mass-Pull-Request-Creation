#!/bin/bash

declare scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
declare currDate=`date +"%Y-%m-%d_%H-%M-%S"`

#given avariable, return that variable if it is not empty.
#If it is empty, prompt the user to enter it with a custom message
function promptUserForValueIfEmpty(){
    #check if we actually recieved the cli argument
    if [ -z "$1" ];
    then
        read -p "$2" result
        echo "$result"
    else
        echo "$1"
    fi 
}
sourceBranchNameStripped=$(promptUserForValueIfEmpty "$1" "Please Enter your source branch name: ")
#this will be what we use as the commit message for all our git commits
commitMessage=$(promptUserForValueIfEmpty "$2" "Please enter your commit message: ")

echo "the source branch name is: $sourceBranchNameStripped"
echo "the commit message is: $commitMessage"

#now we analyze all the folders in the git base folder to see which of them are actually git repos

#waits for the user to press the any key
read -r -p "Press the any key to continue " input

