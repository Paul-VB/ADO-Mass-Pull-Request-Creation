#!/bin/bash

configFilePath="./config.cfg"
if [[ -f ${configFilePath} ]]; then
    echo "the config file exists"
    source ${configFilePath} 

else
    echo "it does not exist"
fi

echo "egg: $egg"