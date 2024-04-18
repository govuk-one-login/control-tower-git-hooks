#!/usr/bin/env bats

@test "Check if account name contains an underscore" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 2 ]
    echo "$output" | grep "The account di-account_2 contains an underscore, which is invalid. Account names cannot contain an underscore."
}
