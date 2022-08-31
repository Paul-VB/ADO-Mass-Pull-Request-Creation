#!/bin/bash
declare scriptPath
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";

#press the any key
source "$scriptPath/Core-Scripts/commonUtils.sh"

nugetPackageVersionsFilePath="./NuGetPackages.txt"

#check if the nugetPackageVersionsFile exists
if [[ -f ${nugetPackageVersionsFilePath} ]]; then
    sh 'Core-Scripts/CheeseModeUpdateNugetPackageVersions.sh' "$(<${nugetPackageVersionsFilePath})"
else
    echo "${nugetPackageVersionsFilePath} does not exist."
    pressAnyKeyToContinue
fi