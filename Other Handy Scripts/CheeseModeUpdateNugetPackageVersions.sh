#!/bin/bash

#first, read the list of nugetPackages that need updating
readarray -t nugetPackages < "./NuGetPackages.txt"


gitRoot="C:\git";

tempDir="/tmp"

newPackageVersion="3.0.170"


echo "replacing old version numbers with new version numbers. this might take a minute..."

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

function updateCurrentRepo(){
    #we know we're in a git repo.
    #local -a projFiles
    #projFiles=(" $(findAllProjFiles) ")
    readarray -t projFiles <<< "$(findAllProjFiles)"
    # mapfile -t projFiles < "$(findAllProjFiles)"
    for currProjFile in "${projFiles[@]}"; do
        if [[ -f $currProjFile ]]; then
            for currNugetPackage in "${nugetPackages[@]}" ; do
                currNugetPackage=$(echo "${currNugetPackage}" | sed -E 's/\r//g')
                updateProjfileNuGetPackageVersion "${currProjFile}" "${currNugetPackage}" "${newPackageVersion}"
            done
            echo "$currProjFile has been updated"
        fi
    done
}

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

updateAllRepos
echo "finished"


