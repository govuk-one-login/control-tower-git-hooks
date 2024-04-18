#!/usr/bin/env bats

@test "Check if email address too long" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 2 ]
    echo "$output" | grep "which is longer than the max of 64 characters"
}
