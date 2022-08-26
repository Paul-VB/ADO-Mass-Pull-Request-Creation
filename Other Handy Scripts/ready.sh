#!/bin/bash
readarray -t nugetPackagesAndVersions < "./NuGetPackages.txt"

for currNugetPackageAndVersion in "${nugetPackagesAndVersions[@]}" ; do
    currNugetPackageAndVersion=$(echo "${currNugetPackageAndVersion}" | sed -E 's/\r//g')
    IFS=',';
    currNugetPackageAndVersion=(${currNugetPackageAndVersion})
    unset IFS;
    currNugetPackage=${currNugetPackageAndVersion[0]}
    newPackageVersion=${currNugetPackageAndVersion[1]}
    echo "nugetPackage is: '$currNugetPackage' ; and the version should be: '$newPackageVersion'"
done