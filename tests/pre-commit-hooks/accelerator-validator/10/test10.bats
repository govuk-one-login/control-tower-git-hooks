#!/usr/bin/env bats

@test "Check if config files are missing" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 2 ]
    echo "$output" | grep "Cannot find the accounts-config.yaml, organization-config.yaml or customizations-config.yaml files, please make sure you run this script from the directory that contains those files"
}
