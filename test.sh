#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

main() {
    if [[ $# -eq 0 ]]; then
        echo No function called
        exit
    fi

     keyValue="$1"
     #echo $keyValue
     case $keyValue in 
         update-git-project)
             shift
             gitProjectUpdate "$@"
             ;;
         build-with-xcode)
             shift
             function2 "$@"
             ;;
         *)
             shift
             echo default case for now
            ;;
        esac
}

buildXcodeProject() {
    CONFIGURATION_BUILD_DIR=/tmp/omrecord
    APPIUM_PROJECT_RESOURCE_DIR=~/Git/omsignal-appium/src/main/resources/apps

    WORKSPACE=$1
    SCHEME=$2
    CONFIGURATION_BUILD=$3

    if [[ -z "$WORKSPACE" || -z "$SCHEME" || -z "$CONFIGURATION_BUILD" ]]; then
         echo -e "${RED}No WORKSPACE, SCHEME or CONFIGURATION_BUILD parameters provided"
         exit 1
    fi

     #if [[ "$CONFIGURATION_BUILD" != "QA" && "$CONFIGURATION_BUILD" !=  "DEV" ]]; then
     #    echo -e "${RED}Invalid CONFIGURATION_BUILD parameter. Choose between QA or DEV"
     #    exit 1
     #fi

     echo "Updating Git project repo: $GIT_PROJECT_DIR"
     cd $GIT_PROJECT_DIR
     git fetch origin
     git reset --hard origin/master

     [ -d $CONFIGURATION_BUILD_DIR ] || mkdir $CONFIGURATION_BUILD_DIR

     echo "Building XCode project $WORKSPACE to directory $CONFIGURATION_BUILD_DIR"
     xcodebuild -workspace $WORKSPACE -scheme $SCHEME -configuration $CONFIGURATION_BUILD CONFIGURATION_BUILD_DIR=$CONFIGURATION_BUILD_DIR || exit 1

     deviceUdid=$(system_profiler SPUSBDataType | sed -n -e '/iPad/,/Serial/p' -e '/iPhone/,/Serial/p' -e '/iPod/,/Serial/p' | grep "Serial Number:" | awk -F ": " '{print $2}')
    
     echo "Device id: $deviceUdid"

     echo "Moving .APP to Appium project resource folder $APPIUM_PROJECT_RESOURCE_DIR"
     cp -R $CONFIGURATION_BUILD_DIR/*.app $APPIUM_PROJECT_RESOURCE_DIR/

     echo "Deleting temp folder $CONFIGURATION_BUILD_DIR"
     rm -r $CONFIGURATION_BUILD_DIR

     echo -e "${GREEN}Done!"
 }














gitProjectUpdate() {
        #echo function1: "$@"
    currentDir=$(pwd)

    if [[ "$#" -eq 0  ]]; then
         if [[ -z $(find $currentDir -type d -name ".git")  ]]; then
             echo -e "${RED}error:${NC}$(pwd) is not a git repository"
             exit 1
         fi

         echo Pulling from Master branch ...
         echo $(git pull)
         return
     fi
    
     if [[ "$#" -eq 1 && "$1" == "-h" || "$1" == "--help"  ]]; then
         gitProjectUpdateHelp
         exit 0
     fi

    while [[ $# -gt 1  ]]
    do 
        case "$1" in 
            -b|--branch)
                branch="$2"
                shift
                ;;
            -u|--url)
                projectUrl="$2"
                shift
                ;;
         esac 
         shift
    done 
     
    if [[ -n "$projectUrl" && -n "$branch" ]]; then
        gitUrlProjectUpdate $projectUrl $currentDir
        gitBranchProjectUpdate $branch
    
    elif [[ -n "$branch"  ]]; then
        gitBranchProjectUpdate $branch

    elif [[ -n "$projectUrl" ]]; then
        gitUrlProjectUpdate $projectUrl $currentDir
        
    else
        echo -e "${RED}error:${NC}Invalide parameters "$@""
        gitProjectUpdateHelp
        exit 1
    fi
}

gitUrlProjectUpdate() {
    url="$1"
    directory="$2"
    repository=$(basename "$url" ".${url##*.}")
    
    echo Updating git project \"$repository\" from \"$url\"...
    cd $directory 
    cd .. 
    rm -rf $repository
    echo $(git clone $url)
    cd $repository
}

gitBranchProjectUpdate() {
    echo Updating git project based on branch \"$1\"
    echo $(git checkout -f $1)
    echo $(git reset --hard)
    echo $(git pull)
}

gitProjectUpdateHelp() {
    functionName="update-git-project"
    echo $functionName
    echo Update existing git project
    echo
    echo USAGE:
    echo -e "\t$functionName [OPTIONS]"   
    echo OPTIONS:
    echo -e "\t -b, --branch\t\tSpecify git branch to update from"
    echo -e "\t -u, --url\t\tSpecify git project url to update from"
}


main "$@"

