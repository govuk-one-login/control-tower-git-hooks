#!/usr/bin/env bats

@test "Check if OU in accounts-config.yaml is in organizations-config.yaml" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 2 ]
    echo "$output" | grep "The account di-account-1 is defined in the Workloads/OU03 OU, this was not found in the organization-config.yaml file"
}
