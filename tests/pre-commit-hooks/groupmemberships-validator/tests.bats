#!/usr/bin/env bats

setup() {
    mkdir ../../../terraform
}

teardown() {
    rm -rf ../../../terraform
}

@test "Ensure when duplicates appear in groupmemberships.tf file (user_id then group_id) the script exits rc 1" {
    cp groupmemberships01.tf ../../../terraform/groupmemberships.tf
    run ../../../pre_commit_hooks/groupmemberships-validator.sh
    [ "$status" -eq 1 ]
    echo "$output" | grep "There are duplicate entries in the groupmemberships.tf file, see below. Please fix."
}

@test "Ensure when no duplicates appear in groupmemberships.tf file (user_id then group_id) the script exits rc 0" {
    cp groupmemberships02.tf ../../../terraform/groupmemberships.tf
    run ../../../pre_commit_hooks/groupmemberships-validator.sh
    [ "$status" -eq 0 ]
    echo "$output" | grep "No duplicates found"
}

@test "Ensure when duplicates appear in groupmemberships.tf file (mixed user_id and group_id sequence) the script exits rc 1" {
    cp groupmemberships03.tf ../../../terraform/groupmemberships.tf
    run ../../../pre_commit_hooks/groupmemberships-validator.sh
    [ "$status" -eq 1 ]
    echo "$output" | grep "There are duplicate entries in the groupmemberships.tf file, see below. Please fix."
}

@test "Ensure when no duplicates appear in groupmemberships.tf (mixed user_id and group_id sequence) file the script exits rc 0" {
    cp groupmemberships04.tf ../../../terraform/groupmemberships.tf
    run ../../../pre_commit_hooks/groupmemberships-validator.sh
    [ "$status" -eq 0 ]
    echo "$output" | grep "No duplicates found"
}

@test "Ensure when groupmemberships.tf file is not found the script exits rc 1" {
    run ../../../pre_commit_hooks/groupmemberships-validator.sh
    [ "$status" -eq 1 ]
    echo "$output" | grep "The groupmemberships file"
    echo "$output" | grep "cannot be found, exiting"
}
