#!/bin/bash

#this is where the config file lives
configFilePath="./Config.cfg"

#this writes out blank config keys to the config file. i know the indentation looks weird on this function, but please keep it as is.
function initBlankConfigFile(){

    echo '#config file for the scripts

#This defines where all the git repos are. Usually something like "C:\git"
gitRoot=""

#this is where temporary files live. Usually something like "/tmp"
tempDir=""

#this is the organization name used in Azure Devops
ADOOrganization=""

' > ${configFilePath}

}

#check if the config file exists. If not, initalize it
if [[ -f ${configFilePath} ]]; then
    echo "${configFilePath} file already exists"
else
    echo "${configFilePath} does not exist. Creating a blank one..."
    initBlankConfigFile
fi