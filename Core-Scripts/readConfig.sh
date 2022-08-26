#!/bin/bash
declare scriptPath
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";

#this is where the main config file should live
configFilePath="${scriptPath}/../config.cfg"

#check if the config file exists
if [[ -f ${configFilePath} ]]; then
    #init the config variables
    source "$configFilePath"
else
    echo "Cannot find config file at: \"$configFilePath\" . Please run initConfig.sh"
    exit 1
fi