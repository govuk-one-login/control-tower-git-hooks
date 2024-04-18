#!/usr/bin/env bats

@test "Check if account has valid prefix" {
    run ../../../../pre_commit_hooks/accelerator-validator.sh
    [ "$status" -eq 2 ]
    echo "$output" | grep "The following accounts appear to have the wrong prefix, please investigate.  Valid prefixes are  di-| dcmaw-| gds-| gdx-| govuk-"
    echo "$output" | grep "fred-account-1"
}
