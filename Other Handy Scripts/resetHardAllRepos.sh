#!/bin/bash
gitRoot="C:\git";
eval cd \"$gitRoot\";
for d in */ ; do 
    eval cd \"$d\";
	if [ -d .git ]; then
		echo "Resetting repo: ${d%/}";
        eval "git reset --hard refs/remotes/origin/HEAD"
	fi
    cd ..; 
done 