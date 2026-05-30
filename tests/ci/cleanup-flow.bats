#!/usr/bin/env bats
# CI flow test: Preview cleanup lifecycle
# Mirrors preview-cleanup.yml (PR closed / branch deleted)
#
# Provisions a minimal preview workspace, then destroys it — validates the
# full cleanup path including workspace state removal from GCS.
# Requires GCP credentials. Set SKIP_TF_TESTS=1 to skip.

MISE="${MISE:-$(command -v mise 2>/dev/null || echo ~/.local/bin/mise)}"

setup_file() {
    if [ -n "${SKIP_TF_TESTS:-}" ]; then
        skip "CI flow tests disabled (SKIP_TF_TESTS=1)"
    fi

    eval "$("${MISE}" env --shell bash 2>/dev/null)" || true

    if [ -z "${GCP_PROJECT_ID:-}" ] || [ -z "${GCP_DEVOPS_PROJECT_ID:-}" ]; then
        skip "GCP not configured (GCP_PROJECT_ID or GCP_DEVOPS_PROJECT_ID not set)"
    fi

    export CI_TEST_WORKSPACE="ci-test-cleanup-$(date +%s)"
    echo "CI_TEST_WORKSPACE=${CI_TEST_WORKSPACE}" > "${BATS_SUITE_TMPDIR}/workspace"
    echo "# Cleanup-flow workspace: ${CI_TEST_WORKSPACE}" >&3

    # Pre-provision the workspace so cleanup tests have something to destroy
    eval "$("${MISE}" env --shell bash 2>/dev/null)" || true
    export TF_VAR_commit_sha
    TF_VAR_commit_sha="$(git rev-parse HEAD)"
    local registry="${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev/${GCP_DEVOPS_PROJECT_ID}/${GCP_DEVOPS_DOCKER_REGISTRY_NAME}"
    export TF_VAR_app_image="${TF_VAR_app_image:-${registry}/nv-gcp-template-web:1.2.6}"
    echo "# Pre-provisioning workspace for cleanup test..." >&3
    "${MISE}" run tf-apply "${CI_TEST_WORKSPACE}" --auto-approve 2>&1 | tail -5 >&3 || true
}

teardown_file() {
    if [ -f "${BATS_SUITE_TMPDIR}/workspace" ]; then
        source "${BATS_SUITE_TMPDIR}/workspace"
        eval "$("${MISE}" env --shell bash 2>/dev/null)" || true
        # Safety net: destroy if tests failed before tf-destroy ran
        "${MISE}" run tf-destroy "${CI_TEST_WORKSPACE}" --auto-approve 2>&1 | tail -3 >&3 || true
        # Delete GCS state file (Terraform leaves it behind; clean up after tests)
        BUCKET_NAME="${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage"
        gsutil rm "gs://${BUCKET_NAME}/${GCP_PROJECT_ID}/${PROJECT}/${CI_TEST_WORKSPACE}.tfstate" 2>/dev/null >&3 || true
        # Remove terraform workspace
        cd infra/environments && terraform workspace select default 2>/dev/null && \
            terraform workspace delete "${CI_TEST_WORKSPACE}" 2>/dev/null >&3 || true
    fi
}

setup() {
    if [ -n "${SKIP_TF_TESTS:-}" ]; then
        skip "CI flow tests disabled (SKIP_TF_TESTS=1)"
    fi
    eval "$("${MISE}" env --shell bash 2>/dev/null)" || true
    source "${BATS_SUITE_TMPDIR}/workspace"
    export TF_VAR_commit_sha
    TF_VAR_commit_sha="$(git rev-parse HEAD)"
    local registry="${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev/${GCP_DEVOPS_PROJECT_ID}/${GCP_DEVOPS_DOCKER_REGISTRY_NAME}"
    export TF_VAR_app_image="${TF_VAR_app_image:-${registry}/nv-gcp-template-web:1.2.6}"
}

@test "cleanup: workspace state exists in GCS before destroy" {
    BUCKET_NAME="${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage"
    EXPECTED_PATH="${GCP_PROJECT_ID}/${PROJECT}/${CI_TEST_WORKSPACE}.tfstate"
    run gsutil ls "gs://${BUCKET_NAME}/${EXPECTED_PATH}"
    [ "$status" -eq 0 ]
}

@test "cleanup: extract_issue_id parses branch name for workspace" {
    source mise-tasks/utils.sh
    run extract_issue_id "feature/PROJ-123-some-feature"
    [ "$status" -eq 0 ]
    [ "$output" = "proj-123" ]
}

@test "cleanup: tf-destroy tears down infrastructure" {
    run "${MISE}" run tf-destroy "${CI_TEST_WORKSPACE}" --auto-approve
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Destroy complete" ]] || [[ "$output" =~ "destroyed" ]]
}

@test "cleanup: no live resources remain after destroy" {
    # After destroy, state should be empty. Use mise run tf-init for proper
    # backend config, then verify terraform state list returns nothing.
    "${MISE}" run tf-init "${CI_TEST_WORKSPACE}"
    cd infra/environments
    run terraform state list
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
