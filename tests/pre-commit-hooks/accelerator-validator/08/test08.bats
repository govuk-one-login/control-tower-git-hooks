#!/usr/bin/env bats

@test "Check if service discovery dynatrace trust is in place" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 2 ]
    echo "$output" | grep "di-account-1 does not have 'CTDynatraceServiceScanNonProdReadOnly' or 'CTDynatraceServiceScanProdReadOnly' applied, please update customizations-config.yaml and add the account to the list"
}
