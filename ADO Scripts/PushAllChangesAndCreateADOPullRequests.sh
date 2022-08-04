#!/bin/bash

#given a cli agrument variable, return that variable if it was supplied.
#If it was not, prompt the user to enter it with a custom message
function getCliAgrument(){
    #check if we actually recieved the cli argument
    if [[ -z $1 ]];
    then
        return $1
    else
        read -p "$2" result
        echo $result
    fi 

}

declare scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
declare currDate=`date +"%Y-%m-%d_%H-%M-%S"`

sourceBranchNameStripped=$(getCliAgrument $1 "\"Please_Enter_your_source_branch_name:_\"")
#this will be what we use as the commit message for all our git commits
commitMessage=$(getCliAgrument $2 "\"Please enter your commit message: \"")

echo "the source branch name is: $sourceBranchNameStripped"
echo "the commit message is: $commitMessage"

#now we analyze all the folders in the git base folder to see which of them are actually git repos

#waits for the user to press the any key
read -r -p "Press the any key to continue " input

