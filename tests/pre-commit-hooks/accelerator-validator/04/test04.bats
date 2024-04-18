#!/usr/bin/env bats

@test "Check if account name contains spaces" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 2 ]
    echo "$output" | grep "The account di-accou nt-1 contains 2 words, this is invalid. Account names must only contain one word."
}
