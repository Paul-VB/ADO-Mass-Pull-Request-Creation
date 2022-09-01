#!/bin/bash
declare scriptPath
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";

#"import" common functions
source "$scriptPath/commonUtils.sh"

# #init the config variables
# source "$scriptPath/../config.cfg"
source "$scriptPath/readConfig.sh" || { pressAnyKeyToContinue && { exit; }; }

#this function finds all the vbproj and csproj files in the current directory
function findAllProjFilesInCurrentRepo(){
    local -a fileNamePatterns
    fileNamePatterns=("*.vbproj" "*.csproj" "packages.config")
    for currFileNamePattern in "${fileNamePatterns[@]}"; do
        local searchResults
        searchResults="$(find "$(pwd -P)" -type f -name "${currFileNamePattern}")"
        if [[ -n $searchResults ]]; then #this is here to prevent echoing out blank lines
            echo -e "$searchResults"
        fi
    done
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

#for a given projfile, update all the nugetPackages listed in nuGetPackageVersionsDict
function updateProjfileAllNugetPackages(){
    local projFile
    projFile="${1}"
    for key in "${!nuGetPackageVersionsDict[@]}"; do
        local currNugetPackage=${key}
        local newPackageVersion=${nuGetPackageVersionsDict[$key]}
        updateProjfileNuGetPackageVersion "${projFile}" "${currNugetPackage}" "${newPackageVersion}"
    done
    echo "${projFile} has been updated"
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
    #<PackageReference Include="example.nuget.package" Version="3.0.165" />
    thingToMatch="(<PackageReference Include=\"${nuGetPackageName}\" Version=\").{1,}?(\".{0,}?\/>)"
    thingToChangeItTo="\${1}${newVersion}\$2"
    findAndReplaceInFile "${projFile}" "${thingToMatch}" "${thingToChangeItTo}"

    #these update the "refrence" ones
    #<Reference Include="example.nuget.package, Version=3.0.165.0, Culture=neutral, processorArchitecture=MSIL">
    thingToMatch="(<Reference Include=.{0,}?${nuGetPackageName}[^\n]{1,}? Version=)[^\n,]{1,}(.{1,}?<\/Reference>)"
    thingToChangeItTo="\${1}${newVersion}\$2"
    findAndReplaceInFile "${projFile}" "${thingToMatch}" "${thingToChangeItTo}"

    #these update the hintpath things
    #<HintPath>$(SolutionDir)\packages\example.nuget.package.3.0.165\lib\netstandard2.0\example.nuget.package.dll</HintPath>
    thingToMatch="(<HintPath[^>]{0,}?>.{0,}?${nuGetPackageName}.)[^\s\\\\\/]{1,}(.{0,}?<\/HintPath>)"
    thingToChangeItTo="\${1}${newVersion}\$2"
    findAndReplaceInFile "${projFile}" "${thingToMatch}" "${thingToChangeItTo}"

    #updating the 
    #<package id="example.nuget.package" version="3.0.165" targetFramework="net47" />
    thingToMatch="(<package id=\"${nuGetPackageName}\".{0,}?version=\").{1,}?(\".{0,}?\/>)"
    thingToChangeItTo="\${1}${newVersion}\$2"
    findAndReplaceInFile "${projFile}" "${thingToMatch}" "${thingToChangeItTo}"
}

#Updates all proj files that are inside of repos in the git root folder
function updateAllProjFiles(){
    #we know we're in a git repo.
    echo "Searching for all proj files in ${gitRoot}..."
    readarray -t projFiles <<< "$(findAllProjFiles)"
    declare numberOfProjFiles=${#projFiles[*]}
    echo "${numberOfProjFiles} proj files found."
    # mapfile -t projFiles < "$(findAllProjFiles)"
    for currProjFile in "${projFiles[@]}"; do
        if [[ -f $currProjFile ]]; then
            updateProjfileAllNugetPackages "$currProjFile"&
        fi
    done
    wait
}

#for every repo, find the full path of every single proj file
function findAllProjFiles(){
    eval cd \"$gitRoot\" || { true; };
    for currDirectory in */ ; do 
        currDirectory=${currDirectory::-1} #this strips off the trailing /
        eval cd \"$currDirectory\" || { true; };
        if [ -d .git ]; then
            findAllProjFilesInCurrentRepo &
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

updateAllProjFiles
wait
echo "finished"
date -ud "@$SECONDS" "+Time elapsed: %H:%M:%S" #i dont know why this works, but it works

#waits for the user to press the any key
pressAnyKeyToContinue