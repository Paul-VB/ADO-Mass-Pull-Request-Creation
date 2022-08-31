#!/bin/bash
declare scriptPath
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";

#"import" common functions
source "$scriptPath/commonUtils.sh"

# #init the config variables
# source "$scriptPath/../config.cfg"
source "$scriptPath/readConfig.sh" || { pressAnyKeyToContinue && { exit; }; }

#executes the checkChange script
function checkChanges(){
    "$scriptPath/checkChanges.sh"
}

#given a string, return that string such that it could be used as a valid git branch name
#with invalid characters stripped out or replaced
function createValidGitBranchName(){
    result="$1"
    #strip out spaces and commas
    result="${result//,/_}"
    result="${result// /_}"
    echo "$result"
}

#this function takes a directory that is known to be a git repo with unmerged changes.
#It create a new branch, adds all changes to the new branch, creates a remote branch and pushes to it,
function createBranchAndPushToRemote(){
    #first, lets get a branch name that is not already in use
    local uniqueBranchName
    uniqueBranchName=$(getSimilarButUnusedNewBranchName $sourceBranchName)

    #next, lets create the new branch. If any errors happen, dont go any further
    eval "git checkout -b $uniqueBranchName"
    if [ $? -ne 0 ]; then
        echo "ERROR: for git repo $repo, $uniqueBranchName is not a valid branch name" 1>&2
        return 1        
    fi
    #if that went well, continue
    eval "git add -A"
    eval "git commit -m '${commitMessage}'"
    eval "git push origin $uniqueBranchName"
    return 0
}

#In the current git repo we're in, check if the supplied branch name already exists remotley.
#If it does exist, then return a similar name that is unused.
#if it does not exist, then return the branch name as-is
function getSimilarButUnusedNewBranchName (){
    local branchName=${1}
    # declare -a similarBranches=($(git ls-remote | grep $branchName))
    # declare -a similarBranches=($(git ls-remote --exit-code --heads origin $branchName))
    declare -a similarBranches=($(git branch -a | grep $branchName))

    if [[ ${#similarBranches[*]} -eq "0" ]]; then
        echo $branchName
    else
        #we know we'll have to append a .number after the branch name
        existingTrailingNumber=$(grep -oh --regexp=\\.[0-9][0-9]*$ <<< $branchName) #this regex grabs a period and any numbers at the end of a string, if there are any
        stuffThatComesBeforeTheTrailingNumbers=$(grep -Poh --regexp=^..*\(?=\\.[0-9][0-9]*$\) <<< $branchName)
        if [[ -z $existingTrailingNumber ]]; then
            echo $(getSimilarButUnusedNewBranchName "${branchName}.1");
        else
            nextNumber=$((${existingTrailingNumber:1}+1)) #adds 1 to the end thing
            echo $(getSimilarButUnusedNewBranchName "${stuffThatComesBeforeTheTrailingNumbers}.${nextNumber}");
        fi
    fi
}

#in the current git repo, create a pull request to merge the current branch with the default branch
function createADOPullRequest(){
    local repo=($(basename $(pwd)))
    currentBranchName=$(getCurrentBranchName)
    targetBranchName=$(getDefaultBranchName)
    newPrUrl="https://dev.azure.com/${ADOOrganization}/_git/${repo}/pullrequestcreate?sourceRef=${currentBranchName}&targetRef=${targetBranchName}"
    echo $newPrUrl >> "$scriptPath/$PrListFilePath"
    eval "start $newPrUrl"
}

#CD into a repo, create a branch and push it to the origin, and create an ADO pull request for it
function branchAndCreatePR(){
	local repo=${1}
    eval cd \"$repo\" || { true; };
    createBranchAndPushToRemote
    if [ $? -eq 0 ]; then #Only make the PR if the branching process did not error
        createADOPullRequest
    else
        echo -e $LightRed"Skipping PR creation for repo $repo"$NoColor; 
    fi
    
    cd ..; 
}

#where "main" starts
declare currDate="$(date +"%Y-%m-%d_%H-%M-%S")";

setTerminalTitle "Push All Changes"
#this is the source branch name that all our commits will use
sourceBranchName=$(promptUserForValueIfEmpty "$1" "Please Enter your source branch name: ")
sourceBranchName=$(createValidGitBranchName "$sourceBranchName")

#this will be what we use as the commit message for all our git commits
commitMessage=$(promptUserForValueIfEmpty "$2" "Please enter your commit message: ")

#this will become part of the pull request creation URL.
#ADOOrganization=$(promptUserForValueIfEmpty "$3" "Please enter the Organization part of the Azure Devops URL: ")
#ADOOrganization is defined in the config file

echo -e "the source branch name is:$LightYellow $sourceBranchName $NoColor"
echo -e "the commit message is:$LightYellow $commitMessage $NoColor"
echo -e "the ADOOrganization is:$LightYellow $ADOOrganization $NoColor"

#ask the user to confirm if they want to continue
shouldContinue=$(promptUserForYesOrNo "Do the source branch and commit messages look correct? (Y/N)" )
if [[ "$shouldContinue" == "False" ]]; then
    echo "Aborting..."
    pressAnyKeyToContinue
    exit 1
fi

#this will be where the list of pull request links will be placed.
declare PrListFilePath="PR List For ${commitMessage}_${currDate}.txt"

#now we analyze all the folders in the git base folder to see which of them are actually git repos
mapfile -t ReposWithChanges <<< "$(checkChanges)"

declare ReposWithChangesCount=${#ReposWithChanges[*]}

echo "Number of Repos with changes: $ReposWithChangesCount"
if [[ "$ReposWithChangesCount" -eq "0" ]]; then
    echo -e "All repos are clean!";
else
    echo "Get ready for git spam..."
    for repo in "${ReposWithChanges[@]}" ; do 
        echo "dirty repo $repo"
        #branchAndCreatePR $repo &
    done 
    wait
fi

#waits for the user to press the any key
pressAnyKeyToContinue