#!/bin/bash
declare scriptPath
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";

#"import" common functions
source "${scriptPath}/../Core-Scripts/commonUtils.sh"

getDefaultBranchName

#resets to the default branch, and pulls
function reset(){
    local defaultBranchName
    defaultBranchName="$(getDefaultBranchName)"
    eval "git checkout ${defaultBranchName}"
    eval "git reset --hard ${defaultBranchName}"
    eval "git pull"
    eval "git clean -f"
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
wait