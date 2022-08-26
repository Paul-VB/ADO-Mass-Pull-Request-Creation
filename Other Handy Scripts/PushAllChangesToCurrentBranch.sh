#!/bin/bash
gitRoot="C:\git";
eval cd \"$gitRoot\";

#get the current branch name of the current repository
function getCurrentBranchName(){
    echo "$(eval "git symbolic-ref HEAD | sed 's@^refs/heads/@@'")"
}

function updateCurrentRepo(){
    eval "git add -A"
    eval "git commit -m 'doing a roar'"
    currBranch="$(getCurrentBranchName)"
    eval "git push -u origin ${currBranch}"
}

eval cd \"$gitRoot\" || { true; };
for currDirectory in */ ; do 
    currDirectory=${currDirectory::-1} #this strips off the trailing /
    eval cd \"$currDirectory\" || { true; };
    if [ -d .git ]; then
        echo "updating repo: ${currDirectory}";
        updateCurrentRepo &
    fi
    cd ..; 
done 
wait

read -r -p "Press the any key to continue " input