#!/usr/bin/env bats

@test "Check for duplicate email address in config" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 2 ]
    echo "$output" | grep "The above email address is a duplicate in the accounts-config.yaml file"
}
