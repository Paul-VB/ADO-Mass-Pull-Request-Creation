#!/bin/bash

#first, lets prompt the user to enter what the git commit message will be
read -p "Please enter the release number of your update: " releaseNumber
read -p "Please enter the name(s) of the NuGet package(s) you are updating (separated by spaces and/or commas): " nugetPackageName
#strip out spaces and commas from the nugetPackageName
declare nugetPackageNameStripped=$nugetPackageName
nugetPackageNameStripped="${nugetPackageNameStripped//,/_}"
nugetPackageNameStripped="${nugetPackageNameStripped// /_}"

declare sourceBranchName="feature/updating_${nugetPackageNameStripped}_to_Release_${releaseNumber}"
declare commitMessage="Updating NuGet package(s): $nugetPackageName to to version: $releaseNumber"
declare ADOOrganization="npsnatgen/NPS"

sh 'Core Scripts/PushAllChangesAndCreateADOPullRequests.sh' "$sourceBranchName" "$commitMessage" "$ADOOrganization"