#!/bin/bash
declare scriptPath
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";

#init the pretty colors
source "$scriptPath/prettyColors.sh"

#press the any key
source "$scriptPath/pressAnyKeyToContinue.sh"

# #init the config variables
# source "$scriptPath/../config.cfg"
sh "$scriptPath/readConfig.sh" || pressAnyKeyToContinue && { exit; };

#sets the title of the terminal window
function setTerminalTitle(){
    echo -ne "\e]0;${1}\a"
}

#given a variable, return that variable if it is not empty.
#If it is empty, prompt the user to enter it with a custom message
function promptUserForValueIfEmpty(){
    #check if we actually recieved the cli argument
    if [ -z "$1" ];
    then
        read -r -p "$2" result
        echo "$result"
    else
        echo "$1"
    fi 
}

#asks the user a yes or no question
function promptUserForYesOrNo(){
    local prompt
    prompt="$1"
    while true
        do
        read -r -p "$prompt [Y/n]" input
        case $input in
        [yY][eE][sS]|[yY])
            echo "True"
        break
        ;;
        [nN][oO]|[nN])
            echo "False"
        break
        ;;
        *)
            echo "Invalid input..." >&2
        ;;
        esac
    done
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

#get the default branch name of the current repository
function getDefaultBranchName(){
    echo "$(eval "git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'")"
}

#get the current branch name of the current repository
function getCurrentBranchName(){
    echo "$(eval "git symbolic-ref HEAD | sed 's@^refs/heads/@@'")"
}

touch "$tempDir/ReposWithChangesTmpFile"
#this function checks a directory, and if it's a git repo with unmerged changes, add that directory to gitRepoHasUnmergedChanges
function checkIfDirectoryIsGitRepoWithUnmergedChanges(){
    local currDirectory=${1}
    eval cd \"$currDirectory\" || { true; }; #the `|| { true; };` code basically says "do a command, but if it errors, do nothing"
	if [ -d .git ]; then
        #we know we're in a git repo. Does the git repo have unmerged changes?
        if output=$(git status --porcelain) && [ -z "$output" ]; then
			# Working directory clean
            echo -ne $LightGreen"\r\033[0K$currDirectory has no changes"$NoColor;
		else 
			# Uncommitted changes
			echo -e $LightRed"\r\033[0K$currDirectory has changes"$NoColor;
			echo "$currDirectory" >> "$tempDir/ReposWithChangesTmpFile"
		fi
	fi
	cd ..; 
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
declare scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )";
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
eval cd \"$gitRoot\" || { exit; };
for currDirectory in */ ; do 
    #haha parallelization go brr
    currDirectory=${currDirectory::-1} #this strips off the trailing /
    checkIfDirectoryIsGitRepoWithUnmergedChanges $currDirectory &
done 
wait
mapfile -t ReposWithChanges < "$tempDir/ReposWithChangesTmpFile"
echo -e "\nChecked all repos";
rm "$tempDir/ReposWithChangesTmpFile"

declare ReposWithChangesCount=${#ReposWithChanges[*]}

echo "Number of Repos with changes: $ReposWithChangesCount"
if [[ "$ReposWithChangesCount" -eq "0" ]]; then
    echo -e "All repos are clean!";
else
    echo "Get ready for git spam..."
    for repo in "${ReposWithChanges[@]}" ; do 
        branchAndCreatePR $repo &
    done 
    wait
fi

#waits for the user to press the any key
pressAnyKeyToContinue