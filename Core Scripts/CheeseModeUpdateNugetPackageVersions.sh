#!/bin/bash

#the contents of the nugetPackageVersion file should be such that each line is: the nugetPackge name, a comma(,), the new version number
#for example:
#someRandomNugetPackage,1.2.3
#someOtherNugetPackage,69
#someThirdPackage,420.1
nugetPackageVersionsFile="./NuGetPackages.txt"
gitRoot="C:\git";

#this function finds all the vbproj and csproj files in the current directory
function findAllProjFiles(){
    local fileNamePattern
    fileNamePattern="*.[vc][bs]proj"
    local searchResults
    searchResults="$(find "$(pwd -P)" -type f -name "${fileNamePattern}")"
    if [[ -n $searchResults ]]; then #this is here to prevent echoing out blank lines
        echo -e "$searchResults"
    fi
}

#for a given file, find and replace in-place a provided regexString (thingToMatch) with a replacement string (thingToChangeItTo)
function findAndReplaceInFile(){
    local filePath
    filePath="${1}"
    local thingToMatch
    thingToMatch="${2}"
    local thingToChangeItTo
    thingToChangeItTo="${3}"
    perl -w -i -p -00e "s/${thingToMatch}/${thingToChangeItTo}/gs" "$filePath"
}

#for a given projfile, update the given nugetpackage to the given newVersion
function updateProjfileNuGetPackageVersion(){
    local projFile
    projFile="${1}"
    local nuGetPackageName
    nuGetPackageName="${2}"
    local newVersion
    newVersion="${3}"

    #now we find and replace in files
    local thingToMatch
    local thingToChangeItTo

    #these update the multi-line packagerefs
    thingToMatch="(<PackageReference Include=\"${nuGetPackageName}\">.{1,}?<Version>).{1,}?(<\/Version>)"
    thingToChangeItTo="\${1}${newVersion}\$2"
    findAndReplaceInFile "${projFile}" "${thingToMatch}" "${thingToChangeItTo}"

    #these update the singleLine package refs
    #<PackageReference Include="PLModels" Version="3.0.165" />
    thingToMatch="(<PackageReference Include=\"${nuGetPackageName}\" Version=\").{1,}?(\".{0,}?\/>)"
    thingToChangeItTo="\${1}${newVersion}\$2"
    findAndReplaceInFile "${projFile}" "${thingToMatch}" "${thingToChangeItTo}"

}

#in the current repo, update all the projFiles to have newer nugetPackage versions
function updateCurrentRepo(){
    #we know we're in a git repo.
    #local -a projFiles
    #projFiles=(" $(findAllProjFiles) ")
    readarray -t projFiles <<< "$(findAllProjFiles)"
    # mapfile -t projFiles < "$(findAllProjFiles)"
    for currProjFile in "${projFiles[@]}"; do
        if [[ -f $currProjFile ]]; then
            for currNugetPackageAndVersion in "${nugetPackagesAndVersions[@]}" ; do
            currNugetPackageAndVersion=$(echo "${currNugetPackageAndVersion}" | sed -E 's/\r//g')
            IFS=',';
            currNugetPackageAndVersion=(${currNugetPackageAndVersion})
            unset IFS;
            currNugetPackage=${currNugetPackageAndVersion[0]}
            newPackageVersion=${currNugetPackageAndVersion[1]}
            updateProjfileNuGetPackageVersion "${currProjFile}" "${currNugetPackage}" "${newPackageVersion}"
        done
        echo "$currProjFile has been updated"
        fi
    done
}

#this function loops through all the folders in the current directory. If that folder is a git repo, then begin updating it's nugetPackage versions
function updateAllRepos(){
    eval cd \"$gitRoot\" || { true; };
    for currDirectory in */ ; do 
        currDirectory=${currDirectory::-1} #this strips off the trailing /
        eval cd \"$currDirectory\" || { true; };
        if [ -d .git ]; then
            updateCurrentRepo &
        fi
        cd ..; 
    done 
    wait
}
echo "replacing old version numbers with new version numbers. this might take a minute, and slow down your computer..."
#first, read the list of nugetPackages that need updating
readarray -t nugetPackagesAndVersions < "$nugetPackageVersionsFile"
updateAllRepos
echo "finished"
date -ud "@$SECONDS" "+Time elapsed: %H:%M:%S" #i dont know why this works, but it works
read -r -p "Press the any key to continue " input