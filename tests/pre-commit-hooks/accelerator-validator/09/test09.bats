#!/usr/bin/env bats

@test "Check if dynatrace prod/non-prod trust is in place" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 2 ]
    echo "$output" | grep "This test has failed, please see the output from diff above.  Check that all Workloads child OUs are deployment targets of the CTDynatraceServiceDiscoveryReadOnly stack in customizations-config.yaml"
}
