#!/bin/bash

#first, read the list of nugetPackages that need updating
readarray -t nugetPackages < "./NuGetPackages.txt"


gitRoot="C:\git\PL";

newPackageVersion="3.0.170"

eval cd \"$gitRoot\" || { true; };
echo "replacing old version numbers with new version numbers. this might take a minute..."

function overwriteNuGetPackageVersion(){
    local nuGetPackageName="${1}"
    local newVersion="${2}"
    local thingToMatch="(<PackageReference Include=\"${nuGetPackageName}\">.{1,}?<Version>)[\.\d]{1,}?(<\/Version>)"
    local thingToChangeItTo="\${1}${newVersion}\$2"
    find . -type f -name '*.[vc][bs]proj' -exec perl -w -i -p -00e "s/${thingToMatch}/${thingToChangeItTo}/gs" {} \;
}

for currNugetPackage in "${nugetPackages[@]}" ; do
    currNugetPackage=$(echo "${currNugetPackage}" | sed -E 's/\r//g')
    echo -e "trying to update ${currNugetPackage} to version ${newPackageVersion}";
    overwriteNuGetPackageVersion "${currNugetPackage}" "${newPackageVersion}" &
done