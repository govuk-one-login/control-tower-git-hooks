#!/usr/bin/env bats

setup() {
    mkdir ../../../terraform
}

teardown() {
    rm -rf ../../../terraform
}

@test "Ensure when duplicates appear in permissionsets.tf file (modules) the script exits rc 1" {
    cp permissionsets01.tf ../../../terraform/permissionsets.tf
    run ../../../pre_commit_hooks/permissionsets-validator.sh
    [ "$status" -eq 1 ]
    echo "$output" | grep "Duplicate modules found in"
    echo "$output" | grep "Dupes found, exiting with error code 1..."
}

@test "Ensure when duplicates appear in permissionsets.tf file (permissionsets) the script exits rc 1" {
    cp permissionsets02.tf ../../../terraform/permissionsets.tf
    run ../../../pre_commit_hooks/permissionsets-validator.sh
    [ "$status" -eq 1 ]
    echo "$output" | grep "Duplicate permissionset names found in"
    echo "$output" | grep "Dupes found, exiting with error code 1..."
}

@test "Ensure when duplicates appear in permissionsets.tf file (modules and permissionsets) the script exits rc 1" {
    cp permissionsets03.tf ../../../terraform/permissionsets.tf
    run ../../../pre_commit_hooks/permissionsets-validator.sh
    [ "$status" -eq 1 ]
    echo "$output" | grep "Duplicate modules found in"
    echo "$output" | grep "Duplicate permissionset names found in"
    echo "$output" | grep "Dupes found, exiting with error code 1..."
}

@test "Ensure when no duplicates appear in permissionsets.tf file the script exits rc 0" {
    cp permissionsets04.tf ../../../terraform/permissionsets.tf
    run ../../../pre_commit_hooks/permissionsets-validator.sh
    [ "$status" -eq 0 ]
    echo "$output" | grep "No dupes found, exiting with error code 0..."
}

@test "Ensure when a permission set name contains spaces in permissionsets.tf file the script exits rc 1" {
    cp permissionsets05.tf ../../../terraform/permissionsets.tf
    run ../../../pre_commit_hooks/permissionsets-validator.sh
    [ "$status" -eq 1 ]
    echo "$output" | grep "Permission set names containing a space found in"
}
@test "Ensure permission set name exceeds 32 characters in permissionsets.tf file the script exits rc 1" {
    cp permissionsets06.tf ../../../terraform/permissionsets.tf
    run ../../../pre_commit_hooks/permissionsets-validator.sh
    [ "$status" -eq 1 ]
    echo "$output" | grep "Names longer than 32 characters found in"
}

@test "Ensure when permissionsets.tf file is not found the script exits rc 1" {
    run ../../../pre_commit_hooks/permissionsets-validator.sh
    [ "$status" -eq 1 ]
    echo "$output" | grep "Permission sets file not found:"
}
