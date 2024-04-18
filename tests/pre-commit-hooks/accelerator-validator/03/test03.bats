#!/usr/bin/env bats

@test "Check if account in suspended OU" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 2 ]
    echo "$output" | grep "The account di-account-2 is defined in the suspended OU, this is invalid"
}
