#!/bin/bash
declare scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
declare currDate=`date +"%Y-%m-%d_%H-%M-%S"`

#for all the repos we push to, this will be the source branch of our PR
declare sourceBranchName

#this will be what we use as the commit message for all our git commits
declare commitMessage

#check if we recieved the source branch name as an argument
if [[ -z $1 ]];
then
    read -p "Please Enter your source branch name: " sourceBranchName
else
    sourceBranchName=$1
fi
#strip out spaces and commas from the sourceBranchName
declare sourceBranchNameStripped=$sourceBranchName
sourceBranchNameStripped="${sourceBranchNameStripped//,/_}"
sourceBranchNameStripped="${sourceBranchNameStripped// /_}"

echo "$sourceBranchNameStripped"

#check if we recieved the git commit message as an argument
if [[ -z $2 ]];
then
    read -p "Please enter your commit message: " commitMessage
else
    commitMessage=$2
fi

#waits for the user to press the any key
read -r -p "Press the any key to continue " input