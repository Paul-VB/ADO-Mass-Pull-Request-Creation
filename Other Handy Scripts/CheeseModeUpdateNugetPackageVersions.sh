#!/bin/bash

#first, read the list of nugetPackages that need updating
readarray -t nugetPackages < "./NuGetPackages.txt"


gitRoot="C:\git";

newPackageVersion="3.0.170"


echo "replacing old version numbers with new version numbers. this might take a minute..."

function overwriteNuGetPackageVersion(){
    local nuGetPackageName="${1}"
    local newVersion="${2}"
    local thingToMatch="(<PackageReference Include=\"${nuGetPackageName}\">.{1,}?<Version>)[\.\d]{1,}?(<\/Version>)"
    local thingToChangeItTo="\${1}${newVersion}\$2"
    find \. -type f -name '*.[vc][bs]proj' -exec perl -w -i -p -00e "s/${thingToMatch}/${thingToChangeItTo}/gs" {} \;
}

function updateAllRepos(){
    eval cd \"$gitRoot\" || { true; };
    for currDirectory in */ ; do 
        currDirectory=${currDirectory::-1} #this strips off the trailing /
        eval cd \"$currDirectory\" || { true; };
        if [ -d .git ]; then
            echo "Updating repo: $currDirectory"
            #we know we're in a git repo. Does the git repo have unmerged changes?
            for currNugetPackage in "${nugetPackages[@]}" ; do
                currNugetPackage=$(echo "${currNugetPackage}" | sed -E 's/\r//g')
                overwriteNuGetPackageVersion "${currNugetPackage}" "${newPackageVersion}" &
            done
        fi
        wait
        cd ..; 
    done 
    wait
}

updateAllRepos
echo "finished"


