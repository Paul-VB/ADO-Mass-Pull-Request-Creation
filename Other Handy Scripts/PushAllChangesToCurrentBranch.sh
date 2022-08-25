#!/bin/bash
gitRoot="C:\git";
eval cd \"$gitRoot\";
for d in */ ; do 
    eval cd \"$d\";
	if [ -d .git ]; then
		echo "updating repo: ${d%/}";
        eval "git add -A"
        eval "git commit -m 'doing a roar'"
        eval "git push"
        fi
    cd ..; 
done 