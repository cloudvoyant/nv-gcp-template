#!/usr/bin/env bats
# Tests for scripts/utils.sh utility functions

setup() {
    source scripts/utils.sh
}

@test "extract_issue_id: extracts various formats" {
    result=$(extract_issue_id "feature/JIRA-123-description")
    [ "$result" = "jira-123" ]

    result=$(extract_issue_id "feature/PROJ-12345-add-feature")
    [ "$result" = "proj-12345" ]

    result=$(extract_issue_id "bugfix/BUG-1-fix")
    [ "$result" = "bug-1" ]
}

@test "extract_issue_id: returns dev for non-feature branches" {
    result=$(extract_issue_id "main")
    [ "$result" = "dev" ]

    result=$(extract_issue_id "random-branch")
    [ "$result" = "dev" ]
}

@test "infer_terraform_workspace: uses explicit environment" {
    result=$(infer_terraform_workspace "stage")
    [ "$result" = "stage" ]

    result=$(infer_terraform_workspace "prod")
    [ "$result" = "prod" ]
}
