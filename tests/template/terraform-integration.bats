#!/usr/bin/env bats
# Integration tests for Terraform infrastructure
#
# These tests require:
# - GCP credentials configured
# - Backend bucket created (${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage)
# - GCP_PROJECT_ID, GCP_DEVOPS_PROJECT_ID available via mise env
#
# Set SKIP_CLEANUP=1 to preserve infrastructure for manual inspection
# Set SKIP_TF_TESTS=1 to skip these tests entirely

MISE="${MISE:-$(command -v mise 2>/dev/null || echo ~/.local/bin/mise)}"

setup() {
    if [ -n "${SKIP_TF_TESTS:-}" ]; then
        skip "Terraform integration tests disabled (SKIP_TF_TESTS=1)"
    fi

    eval "$("${MISE}" env --shell bash 2>/dev/null)" || true

    if [ -z "${GCP_PROJECT_ID:-}" ] || [ -z "${GCP_DEVOPS_PROJECT_ID:-}" ]; then
        skip "GCP environment not configured"
    fi

    export TEST_WORKSPACE="tf-test-$(date +%s)"
    echo "# Test workspace: $TEST_WORKSPACE" >&3
}

teardown() {
    if [ -n "${SKIP_CLEANUP:-}" ]; then
        echo "# Skipping cleanup (SKIP_CLEANUP=1)" >&3
        echo "# Workspace: $TEST_WORKSPACE" >&3
        echo "# Clean up: mise run tf-destroy $TEST_WORKSPACE --auto-approve" >&3
        return 0
    fi

    if [ -n "${TEST_WORKSPACE:-}" ]; then
        echo "# Cleaning up: $TEST_WORKSPACE" >&3
        if ! "${MISE}" run tf-destroy "$TEST_WORKSPACE" --auto-approve 2>&1 | tail -10 >&3; then
            echo "# Warning: tf-destroy failed for $TEST_WORKSPACE" >&3
            echo "# This is expected if no infrastructure was provisioned" >&3
        else
            echo "# Successfully cleaned up $TEST_WORKSPACE" >&3
        fi
    fi
}

@test "tf-create-backend: creates backend bucket" {
    run "${MISE}" run tf-create-backend
    [ "$status" -eq 0 ]
}

@test "tf-init: initializes terraform with correct prefix" {
    run "${MISE}" run tf-init "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Terraform initialized" ]] || [[ "$output" =~ "successfully initialized" ]]
}

@test "tf-plan: generates valid plan" {
    run "${MISE}" run tf-plan "$TEST_WORKSPACE"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Terraform will perform" ]] || [[ "$output" =~ "No changes" ]]
}

@test "tf-apply: provisions infrastructure" {
    run "${MISE}" run tf-apply "$TEST_WORKSPACE" --auto-approve
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Apply complete" ]] || [[ "$output" =~ "complete!" ]]
}

@test "terraform state: stored in correct GCS path" {
    "${MISE}" run tf-apply "$TEST_WORKSPACE" --auto-approve

    BUCKET_NAME="${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage"
    EXPECTED_PATH="${GCP_PROJECT_ID}/${PROJECT}/${TEST_WORKSPACE}.tfstate"
    run gsutil ls "gs://${BUCKET_NAME}/${EXPECTED_PATH}"
    [ "$status" -eq 0 ]
}

@test "tf-destroy: cleans up infrastructure" {
    "${MISE}" run tf-apply "$TEST_WORKSPACE" --auto-approve

    run "${MISE}" run tf-destroy "$TEST_WORKSPACE" --auto-approve
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Destroy complete" ]] || [[ "$output" =~ "destroyed" ]]
}
