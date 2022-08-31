#!/bin/bash
declare scriptPath
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";

#"import" common functions
source "$scriptPath/commonUtils.sh"

# #init the config variables
# source "$scriptPath/../config.cfg"
source "$scriptPath/readConfig.sh" || { pressAnyKeyToContinue && { exit; }; }

#this will be a temporary file that contains a list of all the repos that have unmerged changes
repoFile="$tempDir/ReposWithChangesTmpFile"

#this deletes the file repoWithChangesTmpFile and recreates it as blank
rm "$repoFile" 2> /dev/null
touch "$repoFile"

#this function checks a directory, and if it's a git repo with unmerged changes, add that directory to gitRepoHasUnmergedChanges
function checkIfDirectoryIsGitRepoWithUnmergedChanges(){
    local currDirectory=${1}
    eval cd \"$currDirectory\" || { true; }; #the `|| { true; };` code basically says "do a command, but if it errors, do nothing"
	if [ -d .git ]; then
        #we know we're in a git repo. Does the git repo have unmerged changes?
        if output=$(git status --porcelain) && [ -z "$output" ]; then
			# Working directory clean
            echo -ne $LightGreen"\r$eraseLine$currDirectory has no changes"$NoColor >&2;
		else 
			# Uncommitted changes
			echo -e $LightRed"\r$eraseLine$currDirectory has changes"$NoColor >&2;
			echo "$currDirectory" >> "$repoFile"
		fi
	fi
	cd ..; 
}

#this function checks all directories in the gitroot folder, and spits out all directiories that are git repos that have un-merged changes
function getReposWithUnmergedChanges(){
    #now we analyze all the folders in the git base folder to see which of them are actually git repos that have unmerged changes
    eval cd \"$gitRoot\" || { exit; };
    for currDirectory in */ ; do 
        #haha parallelization go brr
        currDirectory=${currDirectory::-1} #this strips off the trailing /
        checkIfDirectoryIsGitRepoWithUnmergedChanges $currDirectory &
    done 
    wait
    #mapfile -t ReposWithChanges < "$tempDir/ReposWithChangesTmpFile"
    echo -ne "\r${eraseLine}Checked all repos\n" >&2;
    cat "$repoFile"
    rm "$repoFile"
}
getReposWithUnmergedChanges

