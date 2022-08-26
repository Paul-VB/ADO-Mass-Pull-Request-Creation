#!/bin/bash
declare fileThatHoldsTargetPath="biggerRepoPath.txt"
declare targetPath=`cat $fileThatHoldsTargetPath`
declare tempFolderName="TemporaryFolder_dsuifgh5d"
eval "git clone ./ '$tempFolderName'"
eval "cp -r \"$tempFolderName/.\" \"$targetPath\\\\\""
eval "rm -R -f '$tempFolderName'"
eval "rm -R -f '$targetPath'/.git"
eval "rm -R -f '$targetPath'/`basename "$0"`"

read -r -p "Press the any key to continue " input