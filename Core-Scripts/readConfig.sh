#!/bin/bash
declare scriptPath
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";

#this is where the main config file should live
configFilePath="../config.cfg"

#check if the config file exists
if [[ -f ${configFilePath} ]]; then
    #init the config variables
    source "$scriptPath/../config.cfg"
else
    echo "Config file does not exist. Please run initConfig.sh"
    exit 1
fi