#!/bin/bash

#get the default branch name of the current repository
function getDefaultBranchName(){
    echo "$(eval "git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'")"
}

#get the current branch name of the current repository
function getCurrentBranchName(){
    echo "$(eval "git symbolic-ref HEAD | sed 's@^refs/heads/@@'")"
}

#resets to the default branch, and pulls
function reset(){
    eval "git reset --hard origin ${getDefaultBranchName}"
    #eval "git pull"
}

gitRoot="C:\git";
eval cd \"$gitRoot\";
for d in */ ; do 
    eval cd \"$d\";
	if [ -d .git ]; then
		echo "Resetting repo: ${d%/}";
        reset &
	fi
    cd ..; 
done 