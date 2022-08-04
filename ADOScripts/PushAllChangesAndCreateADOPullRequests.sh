#!/bin/bash
declare scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
declare currDate=`date +"%Y-%m-%d_%H-%M-%S"`

echo "Hello World"

#waits for the user to press the any key
read -r -p "Press the any key to continue " input