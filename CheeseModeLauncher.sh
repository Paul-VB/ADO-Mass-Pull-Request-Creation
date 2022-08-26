#!/bin/bash

nugetPackageVersionsFilePath="./NuGetPackages.txt"

#check if the nugetPackageVersionsFile exists
if [[ -f ${nugetPackageVersionsFilePath} ]]; then
    sh 'Core-Scripts/CheeseModeUpdateNugetPackageVersions.sh' "$(<${nugetPackageVersionsFilePath})"
else
    echo "${nugetPackageVersionsFilePath} does not exist."
fi