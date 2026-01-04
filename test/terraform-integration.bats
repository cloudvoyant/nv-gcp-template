#!/usr/bin/env bats
# Integration tests for Terraform infrastructure
#
# These tests require:
# - GCP credentials configured
# - Backend bucket created (${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage)
# - GCP_PROJECT_ID, GCP_DEVOPS_PROJECT_ID set in .envrc
#
# Set SKIP_CLEANUP=1 to preserve infrastructure for manual inspection
# Set SKIP_TF_TESTS=1 to skip these tests entirely

setup() {
    # Skip if disabled
    if [ -n "$SKIP_TF_TESTS" ]; then
        skip "Terraform integration tests disabled (SKIP_TF_TESTS=1)"
    fi

    # Source environment
    if [ -f .envrc ]; then
        set +u  # direnv may have unset vars
        source .envrc
        set -u
    fi

    # Verify required variables
    if [ -z "$GCP_PROJECT_ID" ] || [ -z "$GCP_DEVOPS_PROJECT_ID" ]; then
        skip "GCP environment not configured"
    fi

    # Use unique test workspace
    export TEST_WORKSPACE="tf-test-$(date +%s)"
    echo "# Test workspace: $TEST_WORKSPACE" >&3
}

teardown() {
    # Skip cleanup if requested
    if [ -n "${SKIP_CLEANUP:-}" ]; then
        echo "# Skipping cleanup (SKIP_CLEANUP=1)" >&3
        echo "# Workspace: $TEST_WORKSPACE" >&3
        echo "# Clean up: just tf-destroy $TEST_WORKSPACE --auto-approve" >&3
        return 0
    fi

    # Clean up test infrastructure
    if [ -n "${TEST_WORKSPACE:-}" ]; then
        echo "# Cleaning up: $TEST_WORKSPACE" >&3
        just tf-destroy "$TEST_WORKSPACE" --auto-approve 2>&1 | head -20 >&3 || true
    fi
}

@test "tf-create-backend: creates backend bucket" {
    run just tf-create-backend
    [ "$status" -eq 0 ]
}

@test "tf-init: initializes terraform with correct prefix" {
    run just tf-init "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Terraform initialized" ]] || [[ "$output" =~ "successfully initialized" ]]
}

@test "tf-plan: generates valid plan" {
    run just tf-plan "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Terraform will perform" ]] || [[ "$output" =~ "No changes" ]]
}

@test "tf-apply: provisions infrastructure" {
    run just tf-apply "$TEST_WORKSPACE" --auto-approve
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Apply complete" ]] || [[ "$output" =~ "complete!" ]]
}

@test "terraform state: stored in correct GCS path" {
    just tf-apply "$TEST_WORKSPACE" --auto-approve

    # Verify state exists in correct location
    # Note: GCS backend stores workspaces as <prefix>/<workspace>.tfstate
    # The "env:/" prefix is Terraform's internal representation, not the GCS path
    BUCKET_NAME="${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage"
    EXPECTED_PATH="${GCP_PROJECT_ID}/${PROJECT}/${TEST_WORKSPACE}.tfstate"
    run gsutil ls "gs://${BUCKET_NAME}/${EXPECTED_PATH}"
    [ "$status" -eq 0 ]
}

@test "tf-destroy: cleans up infrastructure" {
    # First provision
    just tf-apply "$TEST_WORKSPACE" --auto-approve

    # Then destroy
    run just tf-destroy "$TEST_WORKSPACE" --auto-approve
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Destroy complete" ]] || [[ "$output" =~ "destroyed" ]]
}
