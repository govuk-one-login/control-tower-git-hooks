# control-tower-git-hooks
This repo contains Control Tower git hooks.  

## Active Hooks

### `accelerator-validator.sh`
This hook performs basic validation of accelerator config files.

### `groupmemberships-validator.sh`
This hook checks for duplicate entries in the groupmemberships.tf file.

### `permissionsets-validator.sh`
This hook performs basic validation of the permissionsets.tf file.

## Adding new hooks
To add new hooks to this repo:-
* create a script (can be written in bash, python etc) and add to appropriate location, e.g. pre-commit hooks can be found in `./pre_commit_hooks` 
* amend `.pre-commit-hooks.yaml` file
* create unit tests in `./tests`
* update the GitHub action workflow `./.github/workflows/runTests.yml`

## Links
Pre-commit framework documetation can be found here - https://pre-commit.com/
