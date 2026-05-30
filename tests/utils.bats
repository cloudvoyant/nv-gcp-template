#!/usr/bin/env bats
# Tests for scripts/utils.sh utility functions

setup() {
    source .mise-tasks/utils.sh
}

@test "extract_issue_id: extracts various formats" {
    result=$(extract_issue_id "feature/JIRA-123-description")
    [ "$result" = "jira-123" ]

    result=$(extract_issue_id "feature/PROJ-12345-add-feature")
    [ "$result" = "proj-12345" ]

    result=$(extract_issue_id "bugfix/BUG-1-fix")
    [ "$result" = "bug-1" ]
}

@test "extract_issue_id: fails for non-feature branches" {
    run extract_issue_id "main"
    [ "$status" -ne 0 ]

    run extract_issue_id "random-branch"
    [ "$status" -ne 0 ]
}

@test "infer_terraform_workspace: uses explicit environment" {
    result=$(infer_terraform_workspace "stage")
    [ "$result" = "stage" ]

    result=$(infer_terraform_workspace "prod")
    [ "$result" = "prod" ]
}
