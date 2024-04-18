#!/usr/bin/env bats

@test "Check valid config" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 0 ]
    echo "$output" | grep "No issues detected in the config"
}
