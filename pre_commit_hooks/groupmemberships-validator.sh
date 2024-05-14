#!/bin/bash 

# Variables
userGroupCombo=$(mktemp)

# Main code

set -e 

# We need to figure out where the root of this repo is and then construct a path to the groupmemberships.tf file

repoGitDir=$(git rev-parse --git-dir)
repoRoot=$(cd $repoGitDir && pwd | sed 's/.git$//')

groupmemberships=${repoRoot}/terraform/groupmemberships.tf

# Check that the groupmemberships file can be found in the expected location
if [ ! -f $groupmemberships ]; then
    echo The groupmemberships file $groupmemberships cannot be found, exiting
    exit 1
fi

cat /dev/null > $userGroupCombo

# Read all group and member ids from the groupmemberships file
while read -r one; do
  read -r two

  # The first line is normally the group and the second line the user, but just in case they're in a different sequence let's check
  group=""
  user=""

  if [[ "$one" =~ "group_id" ]]; then
    group=$(echo $one | cut -d'"' -f2)
    user=$(echo $two | cut -d'"' -f2)
  else
    group=$(echo $two | cut -d'"' -f2)
    user=$(echo $one | cut -d'"' -f2)
  fi

  # Record the user and group combination for later comparison
  echo ${group}.${user} >> $userGroupCombo

done <<< "$(grep -E 'group_id|member_id' $groupmemberships)"

# Count the number of user and group combinations from the groupmemberships file
rawUserGroupComboCount=$(cat $userGroupCombo | wc -l)
# Count the unique number of user and group combinations from the groupmemberships file
uniqueUserGroupComboCount=$(cat $userGroupCombo | sort -u | wc -l)

# Compare the above two counts, if there are dupes the counts will be different
if [ $rawUserGroupComboCount != $uniqueUserGroupComboCount ]; then
  echo There are duplicate entries in the groupmemberships.tf file, see below.  Please fix.
  sort $userGroupCombo | uniq -d | sed 's/\./\n/' 
  exit 1
else
  echo No duplicates found
fi

rm -f $userGroupCombo
