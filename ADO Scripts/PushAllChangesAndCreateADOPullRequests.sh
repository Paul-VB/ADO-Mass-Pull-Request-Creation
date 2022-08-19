#!/bin/bash

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


declare scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";
declare currDate=`date +"%Y-%m-%d_%H-%M-%S"`;
gitRoot="C:\git";

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
declare -a ReposWithChanges
eval cd \"$gitRoot\" || { exit; };
for currDirectory in */ ; do 
    eval cd  \"$currDirectory\" || { true; }; #the `|| { true; };` code basically says "do a command, but if it errors, do nothing"
	if [ -d .git ]; then
        #we know we're in a git repo. Does the git repo have unmerged changes?
        if output=$(git status --porcelain) && [ -z "$output" ]; then
			# Working directory clean
			echo -ne $LightGreen"$currDirectory has no changes"$NoColor;
		else 
			# Uncommitted changes
			echo -e $LightRed"$currDirectory has changes"$NoColor;
			ReposWithChanges+=("$currDirectory")
		fi
	fi
    cd ..; 
done 
declare ReposWithChangesCount=${#ReposWithChanges[*]}
echo "ReposWithChangesCount is $ReposWithChangesCount"


#in the current git repo, try to make a new branch with the name of the source branch
# eval "git checkout -b '$sourceBranchName'"
# if [ $? -eq 0 ]; then
#     echo OK
# else
#     echo FAIL
# fi

#waits for the user to press the any key
read -r -p "Press the any key to continue " input

