#!/bin/bash
gitRoot="C:\git";

#get the default branch name of the current repository
function getDefaultBranchName(){
    echo "$(eval "git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'")"
}

#get the current branch name of the current repository
function getCurrentBranchName(){
    echo "$(eval "git symbolic-ref HEAD | sed 's@^refs/heads/@@'")"
}

function resetCurrentRepoToDefaultBranch(){
    local repo=($(basename $(pwd)))
    currentBranchName=$(getCurrentBranchName)
    targetBranchName=$(getDefaultBranchName)
    eval "git checkout -q \"$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')\""
    if [ $? -eq 0 ]; then #Only make the PR if the branching process did not error
        echo "BAD result for $repo is $?"
    else
        echo "GOOD result for $repo is $?"
    fi
}
eval cd \"$gitRoot\";
for d in */ ; do 
    eval cd \"$d\";
	if [ -d .git ]; then
		resetCurrentRepoToDefaultBranch &

	fi
    cd ..; 
done 

