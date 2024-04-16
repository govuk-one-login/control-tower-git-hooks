#! /bin/bash

#
# This script performs checks on the config to ensure that basic rules
# have been adhered to.  A report is generated listing what was checked
# and the overall success or otherwise of the script.
#
# To add a new test:-
# 1. Create a new function, all the logic for the test should be contained in the function.  Use an existing function as a template.
# 2. Call the function from the main code
#

######
#
# Variables
#
######

accountsAndEmails=()
maxEmailLength=64
account=''
email=''
ou=''
validAccountPrefixes=' di-| dcmaw-| gds-| gdx-| govuk-'
maxError='none'
tmpOutFile1=$(mktemp)
tmpOutFile2=$(mktemp)
red='\033[0;31m'
yellow='\033[0;33m'
green='\033[0;32m'
clear='\033[0m'

######
#
# Functions
#
######

function setMaxError {

  case "$maxError" in 
    none)
      maxError=$1
      ;;
    warn)
      if [ "$maxError" != "critical" ]; then
        maxError=$1
      fi
      ;;
    critical)
      maxError=$1
      ;;
    *)
      echo Error can only be set to 'warn' or 'critical'
      exit 1
  esac

}

function evaluateMaxError {

  case "$maxError" in 
    none)
      echo No issues detected in the config
      exit 0
      ;;
    warn)
      echo Issues were detected in the config, please see output from this script
      exit 1
      ;;
    critical)
      echo -e "${red}Critical issues were detected in the config, please see output from this script${clear}"
      exit 2
      ;;
    *)
      ;;
  esac

}

function extractAccountAndEmail { 
  # Read the accounts-config.yaml file and put account, email & OU all on one line
  
  while read -r line; do
    if [[ $line =~ "- name:" ]]; then
      account=''
      email=''
      ou=''
      account=$(echo $line | cut -d'-' -f2-)
    fi

    if [[ $line =~ "email: " ]]; then
      email=$line
    fi

    if [[ $line =~ "organizationalUnit:" ]]; then
      ou=$line
      accountsAndEmails+=("${account}/${email}/${ou}")
    fi
    
  done < accounts-config.yaml
}

function checkForDupeEmails {

  echo Checking for duplicate email addresses.  Email addresses must be unique.

  allEmails=$(grep ' email: ' accounts-config.yaml | sed 's/^.*email://' | sort )

  uniqEmails=$(grep ' email: ' accounts-config.yaml | sed 's/^.*email://' | sort -u)

  diff <( echo $allEmails | sed 's/ /\n/g') <( echo $uniqEmails | sed 's/ /\n/g')

  if [ $? -ne 0 ]; then
    echo -e "${red}Error${clear} - The above email address is a duplicate in the accounts-config.yaml file"
    setMaxError critical
  fi

  echo Check complete
  echo -
}

function validateEmailAddresses {

  echo Validating length of email addresses.  Email addresses can have a max length of $maxEmailLength.

  for i in ${!accountsAndEmails[@]}; do
    email=$(echo ${accountsAndEmails[$i]} | sed 's/^.*email://;s/\/organizationalUnit:.*//' ) # Remove everything before 'email:' from the entry
    emailLength=$(echo -n $email | wc -c)
    if [ $emailLength -gt $maxEmailLength ]; then
      echo -e "${red}Error${clear} - The email $email is $emailLength which is longer than the max of $maxEmailLength characters"
      setMaxError critical
    fi
  done

  echo Check complete
  echo -

  checkForDupeEmails
}

function checkForSuspendedAccounts {

  echo Checking for any suspended accounts.  Accounts in the suspended OU must not appear in the accounts-config.yaml file

  # Any accounts in the suspended OU should not be present in the accounts-config.yaml file
  for i in ${!accountsAndEmails[@]}; do
    ou=$(echo ${accountsAndEmails[$i]} | sed 's/^.*organizationalUnit: //' ) # Remove everything before 'organizationalUnit:' from the entry
    account=$(echo ${accountsAndEmails[$i]} | sed 's/email:.*//' )
    if [ "$ou" == 'suspended' ]; then
      echo -e "${red}Error${clear} - The account $account is defined in the suspended OU, this is invalid"
      setMaxError critical
    fi
  done

  echo Check complete
  echo -

}

function validateAccount {

  echo Checking the validity of the account name.  The account name cannot include a space

  for i in ${!accountsAndEmails[@]}; do
    account=$(echo ${accountsAndEmails[$i]} | sed 's/^.*name://;s/\/email:.*//' ) # Remove everything before 'email:' from the entry
    wordCount=$(echo -n $account | wc -w)
    if [ $wordCount -ne 1 ]; then
      echo -e "${red}Error${clear} - The account "$account" contains $wordCount words, this is invalid.  Account names must only contain one word."
      setMaxError warn
    fi
  done

  echo Check complete
  echo -

}

function validateOU {

  echo Checking the validity of the OU.  Any OU referenced in accounts-config.yaml must also exist in organization-config.yaml

  sed '1,/organizationalUnits:/d;/serviceControlPolicies:/,$d' organization-config.yaml | grep ' - name: ' | grep -v 'suspended' | sed 's/^.*- name: //;s/[[:blank:]]*$//' > $tmpOutFile1

  # Any accounts in the suspended OU should not be present in the accounts-config.yaml file
  for i in ${!accountsAndEmails[@]}; do
    ou=$(echo ${accountsAndEmails[$i]} | sed 's/^.*organizationalUnit: //' ) # Remove everything before 'organizationalUnit:' from the entry
    account=$(echo ${accountsAndEmails[$i]} | sed 's/\/email:.*//' )

    if [ "$ou" != "Root" ]; then # The Root OU is not defined in the orgainization-config.yaml file so do not check 
      grep -Fqx "$ou" $tmpOutFile1

      if [ $? -ne 0 ]; then
        echo -e "${red}Error${clear} - The account $account is defined in the $ou OU, this was not found in the organization-config.yaml file"
        setMaxError critical
      fi
    fi
  done

  echo Check complete
  echo -

}

function validateAccountPrefix {

  echo Checking prefix of account names in the Workload OU.  They should only start with $validAccountPrefixes

  # Get the name and orgainizationalUnit fields from account-config and put each set on the same line.
  # We're only going to check the format of the account name in the Workloads OU for now
  # Ensure that they all start with the correct prefix
  incorrectName=$(grep -E 'name:|organizationalUnit:' accounts-config.yaml | sed '/- name:/N;s/\n//' | grep ' Workloads' | grep -Ev "$validAccountPrefixes")

  if [ $? -eq 0 ]; then
    echo -e "${red}Error${clear} - The following accounts appear to have the wrong prefix, please investigate.  Valid prefixes are $validAccountPrefixes"
    echo $incorrectName
    setMaxError critical
  fi 

  echo Check complete
  echo -

}

function checkForUnderscoreInAccountName {
  echo Checking for underscores in account names. Account names cannot contain an underscore.
  
  for i in ${!accountsAndEmails[@]}; do
    account=$(echo ${accountsAndEmails[$i]} | sed 's/^.*name://;s/\/email:.*//') # Remove everything before 'name:' from the entry
    if [[ "$account" =~ "_" ]]; then
      echo -e "${red}Error${clear} - The account "$account" contains an underscore, which is invalid. Account names cannot contain an underscore."
      setMaxError critical
    fi
  done

  echo Check complete
  echo -

}

function checkWorkloadOuDynatraceTrusts {
  echo For any accounts in Workloads OU they need to have the either the CTDynatraceServiceScanNonProdReadOnly or applied CTDynatraceServiceScanProdReadOnly

  # This seems too complicated, we need to extract the accounts that have either CTDynatraceServiceScanNonProdReadOnly or CTDynatraceServiceScanProdReadOnly
  # applied.

  # Find from 'deploymentTargets' to 'CTDynatraceServiceScanNonProdReadOnly'.  Once 'CTDynatraceServiceScanNonProdReadOnly' has been found stop
  # So we'll end up with lots of 'deploymentTargets' found and the last 'CTDynatraceServiceScanNonProdReadOnly'
  awk '/CTDynatraceServiceScanNonProdReadOnly/{exit} f; /deploymentTargets/{f=1}' customizations-config.yaml > $tmpOutFile1

  # Now find the line number of the last occurance of 'deploymentTargets'
  lineNum=$(grep -n deploymentTargets $tmpOutFile1 | tail -1 | cut -d":" -f1)

  # Now use sed to print from the line number found earlier to the end of the file.  This will be the list of accounts to have 'CTDynatraceServiceScanNonProdReadOnly' deployed
  sed -n "$lineNum,\$p" $tmpOutFile1 | sed '/\:/d' > $tmpOutFile2
  
  # Find from 'deploymentTargets' to 'CTDynatraceServiceScanProdReadOnly'.  Once 'CTDynatraceServiceScanProdReadOnly' has been found stop
  awk '/CTDynatraceServiceScanProdReadOnly/{exit} f; /deploymentTargets/{f=1}' customizations-config.yaml > $tmpOutFile1

  # Now find the line number of the last occurance of 'deploymentTargets'
  lineNum=$(grep -n deploymentTargets $tmpOutFile1 | tail -1 | cut -d":" -f1)

  # Now use sed to print from the line number found earlier to the end of the file.  This will be the list of accounts to have 'CTDynatraceServiceScanNonProdReadOnly' deployed
  sed -n "$lineNum,\$p" $tmpOutFile1 | sed '/\:/d' >> $tmpOutFile2
  
  for i in ${!accountsAndEmails[@]}; do
    ou=$(echo ${accountsAndEmails[$i]} | sed 's/^.*organizationalUnit: //' ) # Remove everything before 'organizationalUnit:' from the entry
    account=$(echo ${accountsAndEmails[$i]} | sed 's/^.*name://;s/\/email:.*//') # Remove everything before 'name:' from the entry

    if [[ "$ou" =~ "Workloads" ]]; then
      grep -q $account $tmpOutFile2
      if [ $? -ne 0 ]; then
        echo -e "${red}Error${clear} - $account does not have 'CTDynatraceServiceScanNonProdReadOnly' or 'CTDynatraceServiceScanProdReadOnly' applied, please update customizations-config.yaml and add the account to the list"
        setMaxError critical
      fi
    fi
  done

  echo Check complete
  echo -

}

function validateDynatraceStack {

  echo Checking that each of the Workloads child and Infrastructure/DNS OUs in organization-config.yaml is included in the list of OUs in CTDynatraceServiceDiscoveryReadOnly

  # Find everything in the customisation file from deploymentTargets up until the stack name CTDynatraceServiceDiscoveryReadOnly
  awk '/CTDynatraceServiceDiscoveryReadOnly/{exit} f; /deploymentTargets/{f=1}' customizations-config.yaml > $tmpOutFile1

  # Now find the line number of the last occurance of 'organizationalUnits'
  lineNum=$(grep -n organizationalUnits $tmpOutFile1 | tail -1 | cut -d":" -f1)

  # Now use sed to print from the line number found earlier to the end of the file.  This will be the list of accounts to have 'CTDynatraceServiceScanNonProdReadOnly' deployed
  sed -n "$lineNum,\$p" $tmpOutFile1 | sed '/\:/d' | awk -F'- ' '{ print $2 }' | sort > $tmpOutFile2

  # Get all child OUs of the Workloads OUs in organization-config.yaml
  sed '1,/organizationalUnits:/d;/serviceControlPolicies:/,$d' organization-config.yaml | grep ' - name: ' | grep -E 'Workloads|Infrastructure/DNS' | sed 's/^.*- name: //;s/[[:blank:]]*$//' | grep -v "^Workloads$" | sort > $tmpOutFile1

  # Compare the two lists of OUs, they should be identical
  diff $tmpOutFile1 $tmpOutFile2

  # If the list isn't identical then Houston, we have a problem
  if [ $? -ne 0 ]; then
    echo -e "${red}Error${clear} - This test has failed, please see the output from diff above.  Check that all Workloads child OUs are deployment targets of the CTDynatraceServiceDiscoveryReadOnly stack in customizations-config.yaml"
    setMaxError critical
  fi 

  echo Check complete
  echo -

}

######
#
# Main code
#
######

if [ -f "accounts-config.yaml" ] && [ -f "customizations-config.yaml" ] && [ -f "organization-config.yaml" ]; then

  extractAccountAndEmail

  validateAccount

  validateEmailAddresses

  checkForSuspendedAccounts

  validateOU

  validateAccountPrefix

  checkForUnderscoreInAccountName

  checkWorkloadOuDynatraceTrusts

  validateDynatraceStack

  evaluateMaxError
else
  echo Cannot find the accounts-config.yaml, organization-config.yaml or customizations-config.yaml files, please make sure you run this script from the directory that contains those files
fi

rm -f $tmpOutFile1
rm -f $tmpOutFile2
