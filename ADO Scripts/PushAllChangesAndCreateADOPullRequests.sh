#!/bin/bash
declare scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
declare currDate=`date +"%Y-%m-%d_%H-%M-%S"`

#this will be what we use as the commit message for all our git commits
declare commitMessage

#check if we recieved the git commit message as an argument
if [[ -z $1 ]];
then
    read -p "Please enter your commit message: " commitMessage
else
    commitMessage=$1
fi

echo "$commitMessage"

#waits for the user to press the any key
read -r -p "Press the any key to continue " input