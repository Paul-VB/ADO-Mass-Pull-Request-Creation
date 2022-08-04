#!/bin/bash
declare scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
declare currDate=`date +"%Y-%m-%d_%H-%M-%S"`

#for all the repos we push to, this will be the source branch of our PR
declare sourceBranchName = getCliAgrument $1 "Please Enter your source branch name: "

#this will be what we use as the commit message for all our git commits
declare commitMessage = getCliAgrument $2 "Please enter your commit message:"

echo "source branch name: $sourceBranchNameStripped"
echo "commit message: $commitMessage"

#now we analyze all the folders in the git base folder to see which of them are actually git repos

#waits for the user to press the any key
read -r -p "Press the any key to continue " input

#given a cli agrument variable, return that variable if it was supplied.
#If it was not, prompt the user to enter it with a custom message
function getCliAgrument(){
    #check if we actually recieved the cli argument
    if [[ -z $1 ]];
    then
        return $1
    else
        read -p "$2" result
        return result
    fi 

}