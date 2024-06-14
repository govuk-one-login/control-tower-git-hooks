#!/bin/bash 

# Variables
permissionSetsTempFile=$(mktemp)
dupesFound=false
red='\033[0;31m'
green='\033[0;32m'
clear='\033[0m'


# Functions
function extractPermissionSetNames {
  # Extract the permission set names from the permission sets file
  numberOfCurlies=0
  echo > $permissionSetsTempFile

  while read -r line; do

    # We're looking for the name of the permission set, which is nested inside a block of curly braces
    
    # We need to keep track of how many curly braces we're inside of
    if [[ $line =~ "{" ]]; then
      ((numberOfCurlies++))
    fi

    # If we find a closing curly brace, we decrement the number of curly braces we're inside of
    if [[ $line =~ "}" ]]; then
      ((numberOfCurlies--))
    fi

    if [[ $numberOfCurlies == 1 ]]; then
      # If we find a name, we write it to a temporary file
      if [[ $line =~ "name " ]]; then
        echo $line | cut -d'"' -f2 >> $permissionSetsTempFile
      fi
    fi

  done < $permissionSetsFile
}

function cleanUp {
  rm $permissionSetsTempFile
}

# Main code

# We need to figure out where the root of this repo is and then construct a path to the groupmemberships.tf file

repoGitDir=$(git rev-parse --git-dir)
repoRoot=$(cd $repoGitDir && pwd | sed 's/.git$//')

permissionSetsFile=${repoRoot}/terraform/permissionsets.tf

if [ -f $permissionSetsFile ]; then

  echo "Running pre-commit hook..."
  echo "Checking for duplicate modules..."

  # Check for duplicate modules
  dupeModules=$(grep "module " $permissionSetsFile | cut -d'"' -f2 | sort | uniq -cd)

  if [ -n "$dupeModules" ]; then
    echo -e "${red}Duplicate modules found in $permissionSetsFile:${clear}"
    echo -e "$dupeModules\n"
    dupesFound=true
  fi

  echo "Checking for duplicate permission sets..."

  extractPermissionSetNames

  # Check for duplicate permission sets
  dupePermissionSets=$(sort $permissionSetsTempFile | uniq -cd)
  if [ -n "$dupePermissionSets" ]; then
    echo -e "${red}Duplicate permissionset names found in $permissionSetsFile:${clear}"
    echo -e "$dupePermissionSets\n"
    dupesFound=true
  fi

  echo "Checking for permission set names longer than 32 characters"

  # Check for names longer than 32 characters
  longNames=$(grep '.\{33,\}' $permissionSetsTempFile)

  if [ -n "$longNames" ]; then
    echo -e "${red}Names longer than 32 characters found in $permissionSetsFile:${clear}"
    echo -e "$longNames\n"
    dupesFound=true
  fi

  echo "Checking for permission set names containing a space"

  # Check for permission set names containing a space
  namesWithSpaces=$(grep -E '[^"]* ' $permissionSetsTempFile)

  if [ -n "$namesWithSpaces" ]; then
    echo -e "${red}Permission set names containing a space found in $permissionSetsFile:${clear}"
    echo -e "$namesWithSpaces\n"
    dupesFound=true
  fi

else
  echo "Permission sets file not found: $permissionSetsFile"
  cleanUp
  exit 1
fi

# Exit with error code 1 if dupes were found
if [ $dupesFound = true ]; then
  echo "Dupes found, exiting with error code 1..."
  exit 1
fi

echo "No dupes found, exiting with error code 0..."

# Clean up
cleanUp
