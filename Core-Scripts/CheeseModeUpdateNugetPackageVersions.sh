#!/bin/bash
declare scriptPath
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";

#init the pretty colors
source "$scriptPath/prettyColors.sh"

#press the any key
source "$scriptPath/pressAnyKeyToContinue.sh"

# #init the config variables
# source "$scriptPath/../config.cfg"
source "$scriptPath/readConfig.sh" || { pressAnyKeyToContinue && { exit; }; }

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

    #these update the "refrence" ones
    #<Reference Include="PL.Contract.Standard, Version=3.0.165.0, Culture=neutral, processorArchitecture=MSIL">
    thingToMatch="(<Reference Include=\"${nuGetPackageName}\"[^\n,]{1,}? Version=)[^\n,]{1,}?(<.{1,}?<\/Reference>)"
    thingToChangeItTo="\${1}${newVersion}\$2"
    findAndReplaceInFile "${projFile}" "${thingToMatch}" "${thingToChangeItTo}"


    #these update the hintpath things
    #<HintPath>$(SolutionDir)\packages\PL.Contract.Standard.3.0.165\lib\netstandard2.0\PL.Contract.Standard.dll</HintPath>
    thingToMatch="(<HintPath[^>]{1,}>${nuGetPackageName})[^\\/ ]{1,}?(<.{1,}?<\/HintPath>)"
    thingToChangeItTo="\${1}${newVersion}\$2"
    findAndReplaceInFile "${projFile}" "${thingToMatch}" "${thingToChangeItTo}"

    #updating the 
    #<package id="PL.Contract.Standard" version="3.0.165" targetFramework="net47" />
    thingToMatch="(<package id=\"${nuGetPackageName}\" Version=\").{1,}?(\".{0,}?\/>)"
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

            for key in "${!nuGetPackageVersionsDict[@]}"; do
                currNugetPackage=${key}
                newPackageVersion=${nuGetPackageVersionsDict[$key]}
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

#this function takes as input key/value pairs from a string and populates a supplied dictionary in-place.
#The KVPs are separated by newlines, and the keys are delimited from the values by commas. and returns a dictionary
#the main use of this function is basicallyy to cat in a file contents and spit out a dictionary
#the contents of the file should look something like this:
#key1,value1
#key2,value2
function populateDictFromNewlineSeparatedStrings(){
    #this is an array of KVPs, but the Keys and values are smushed together. we need to separate them
    local smushedKVPs
    readarray -t smushedKVPs <<< "${1}";

    #this is the dictionary we will populate in-place
    declare -n dictionaryToUpdate="${2}";

    for KVPString in "${smushedKVPs[@]}"; do
        KVPString=$(echo "${KVPString}" | sed -E 's/\r//g') #this strips off pesky carriage returns
        IFS=','; #this sets the delimiter to a comma
        local separatedKVP=(${KVPString})
        unset IFS;
        local key=${separatedKVP[0]}
        local value=${separatedKVP[1]}
        dictionaryToUpdate[$key]=$value
    done
}

#the "main" area

#parse the input recieved from the launcher. This input is literally just the contents of the whole NuGetPackages.txt file
#the contents of the nugetPackageVersion file should be such that each line is: the nugetPackge name, a comma(,), the new version number
#for example:
#someRandomNugetPackage,1.2.3
#someOtherNugetPackage,69
#someThirdPackage,420.1
declare -A nuGetPackageVersionsDict
populateDictFromNewlineSeparatedStrings "${1}" nuGetPackageVersionsDict

echo "replacing old version numbers with new version numbers. this might take a minute, and slow down your computer..."

updateAllRepos
echo "finished"
date -ud "@$SECONDS" "+Time elapsed: %H:%M:%S" #i dont know why this works, but it works

#waits for the user to press the any key
pressAnyKeyToContinue