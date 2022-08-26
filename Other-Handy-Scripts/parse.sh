#!/bin/bash
echo "himom"
readarray -t theBigArray <<< "${1}"
echo "bye mom"

for currNugetPackageAndVersion in "${theBigArray[@]}" ; do
    currNugetPackageAndVersion=$(echo "${currNugetPackageAndVersion}" | sed -E 's/\r//g')
    IFS=',';
    currNugetPackageAndVersion=(${currNugetPackageAndVersion})
    unset IFS;
    currNugetPackage=${currNugetPackageAndVersion[0]}
    newPackageVersion=${currNugetPackageAndVersion[1]}
    echo "curr Nuget Package name: ${currNugetPackage}, and new Package Version: ${newPackageVersion}"
done