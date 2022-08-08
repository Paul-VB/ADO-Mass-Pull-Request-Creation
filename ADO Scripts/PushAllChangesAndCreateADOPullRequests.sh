#!/bin/bash


declare scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";
declare currDate=`date +"%Y-%m-%d_%H-%M-%S"`;
gitRoot="H:\git";

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

#given a string, return that string such that it could be used as a valid git branch name
#with invalid characters stripped out or replaced
function createValidGitBranchName(){
    result="$1"
    #strip out spaces and commas
    result="${result//,/_}"
    result="${result// /_}"
    echo "$result"
}

#get the default branch name of the current repository
function getDefaultBranchName(){
    echo "$(eval "git symbolic-ref --short HEAD")"
}

#this is the source branch name that all our commits will use
sourceBranchName=$(promptUserForValueIfEmpty "$1" "Please Enter your source branch name: ")
sourceBranchName=$(createValidGitBranchName "$sourceBranchName")

#this will be what we use as the commit message for all our git commits
commitMessage=$(promptUserForValueIfEmpty "$2" "Please enter your commit message: ")

echo "the source branch name is: $sourceBranchName"
echo "the commit message is: $commitMessage"

#what the default branchName
defaultBranchName=$(getDefaultBranchName)

echo "the default branch name is $defaultBranchName"

#now we analyze all the folders in the git base folder to see which of them are actually git repos
eval cd \"$gitRoot\" || { exit; };
for currDirectory in */ ; do 
    eval cd  \"$currDirectory\" || { true; }; #the `|| { true; };` code basically says "do a command, but if it errors, do nothing"
	if [ -d .git ]; then
		echo "$currDirectory is a git repo!";
	fi
    cd ..; 
done 


#in the current git repo, try to make a new branch with the name of the source branch
# eval "git checkout -b '$sourceBranchName'"
# if [ $? -eq 0 ]; then
#     echo OK
# else
#     echo FAIL
# fi

#waits for the user to press the any key
read -r -p "Press the any key to continue " input

