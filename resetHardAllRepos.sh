
for d in */ ; do 
    eval cd \"$d\";
	if [ -d .git ]; then
		echo -ne $LightYellow"\r\033[0KResetting ${d%/}"$NoColor;
        eval "git reset --hard refs/remotes/origin/HEAD"
	fi
    cd ..; 
done 