#!/usr/bin/env bats
# CI flow test: Dev/release environment lifecycle
# Mirrors release.yml deploy job (main branch push after semantic-release)
#
# Uses an ephemeral workspace (ci-test-dev-{ts}) to avoid touching the real "dev" env.
# Requires GCP credentials. Set SKIP_TF_TESTS=1 to skip.
# Set RUN_DOCKER_TESTS=1 to include docker build/push steps.
# Set SKIP_CLEANUP=1 to preserve infra after test.

MISE="${MISE:-$(command -v mise 2>/dev/null || echo ~/.local/bin/mise)}"

setup_file() {
    if [ -n "${SKIP_TF_TESTS:-}" ]; then
        skip "CI flow tests disabled (SKIP_TF_TESTS=1)"
    fi

    eval "$("${MISE}" env --shell bash 2>/dev/null)" || true

    if [ -z "${GCP_PROJECT_ID:-}" ] || [ -z "${GCP_DEVOPS_PROJECT_ID:-}" ]; then
        skip "GCP not configured (GCP_PROJECT_ID or GCP_DEVOPS_PROJECT_ID not set)"
    fi

    # Use ephemeral workspace — avoids stomping on real "dev"
    export CI_TEST_WORKSPACE="ci-test-dev-$(date +%s)"
    echo "CI_TEST_WORKSPACE=${CI_TEST_WORKSPACE}" > "${BATS_SUITE_TMPDIR}/workspace"
    echo "# Dev-flow workspace: ${CI_TEST_WORKSPACE}" >&3

    # Ensure nonprod secret exists (required by Terraform plan)
    NONPROD_SECRET="${PROJECT}-secrets-nonprod"
    if ! gcloud secrets describe "${NONPROD_SECRET}" --project="${GCP_DEVOPS_PROJECT_ID}" 2>/dev/null; then
        echo "# Creating placeholder nonprod secret: ${NONPROD_SECRET}" >&3
        printf "KINDE_DOMAIN=placeholder.kinde.com\nKINDE_CLIENT_ID=ci-placeholder\nKINDE_CLIENT_SECRET=ci-placeholder\n" | \
            gcloud secrets create "${NONPROD_SECRET}" --project="${GCP_DEVOPS_PROJECT_ID}" \
                --replication-policy=automatic --data-file=- 2>&1 >&3 || true
    fi
}

teardown_file() {
    if [ -n "${SKIP_CLEANUP:-}" ]; then
        if [ -f "${BATS_SUITE_TMPDIR}/workspace" ]; then
            source "${BATS_SUITE_TMPDIR}/workspace"
            echo "# SKIP_CLEANUP=1: workspace ${CI_TEST_WORKSPACE} preserved" >&3
            echo "# Destroy with: mise run tf-destroy ${CI_TEST_WORKSPACE} --auto-approve" >&3
        fi
        return 0
    fi

    if [ -f "${BATS_SUITE_TMPDIR}/workspace" ]; then
        source "${BATS_SUITE_TMPDIR}/workspace"
        eval "$("${MISE}" env --shell bash 2>/dev/null)" || true
        echo "# Destroying dev-flow workspace: ${CI_TEST_WORKSPACE}" >&3
        "${MISE}" run tf-destroy "${CI_TEST_WORKSPACE}" --auto-approve 2>&1 | tail -5 >&3 || \
            echo "# Warning: tf-destroy failed (infra may not have been provisioned)" >&3
        # Delete GCS state file and terraform workspace record
        BUCKET_NAME="${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage"
        gsutil rm "gs://${BUCKET_NAME}/${GCP_PROJECT_ID}/${PROJECT}/${CI_TEST_WORKSPACE}.tfstate" 2>/dev/null >&3 || true
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

@test "dev: backend bucket exists or is created" {
    run "${MISE}" run tf-create-backend
    [ "$status" -eq 0 ]
}

@test "dev: install dependencies" {
    run "${MISE}" run install
    [ "$status" -eq 0 ]
}

@test "dev: run tests pass (SKIP_TF_TESTS)" {
    run env SKIP_TF_TESTS=1 "${MISE}" run test
    [ "$status" -eq 0 ]
}

@test "dev: build production artifacts" {
    run "${MISE}" run build-prod
    [ "$status" -eq 0 ]
}

@test "dev: publish release package" {
    run "${MISE}" run publish "${CI_TEST_WORKSPACE}"
    [ "$status" -eq 0 ]
}

@test "dev: docker build (skipped unless RUN_DOCKER_TESTS=1)" {
    if [ -z "${RUN_DOCKER_TESTS:-}" ]; then
        skip "Docker tests disabled (set RUN_DOCKER_TESTS=1 to enable)"
    fi
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    run "${MISE}" run docker-build web
    [ "$status" -eq 0 ]
}

@test "dev: docker push (skipped unless RUN_DOCKER_TESTS=1)" {
    if [ -z "${RUN_DOCKER_TESTS:-}" ]; then
        skip "Docker tests disabled (set RUN_DOCKER_TESTS=1 to enable)"
    fi
    run "${MISE}" run docker-login
    [ "$status" -eq 0 ]
    run "${MISE}" run docker-push web
    [ "$status" -eq 0 ]
}

@test "dev: tf-plan succeeds" {
    run "${MISE}" run tf-plan "${CI_TEST_WORKSPACE}"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Plan:" ]] || [[ "$output" =~ "No changes" ]] || [[ "$output" =~ "Terraform will perform" ]]
}

@test "dev: tf-apply provisions infrastructure" {
    run "${MISE}" run tf-apply "${CI_TEST_WORKSPACE}" --auto-approve
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Apply complete" ]] || [[ "$output" =~ "complete!" ]]
}

@test "dev: deploy application" {
    run "${MISE}" run deploy "${CI_TEST_WORKSPACE}"
    [ "$status" -eq 0 ]
}

@test "dev: get-url returns a service URL" {
    run "${MISE}" run get-url "${CI_TEST_WORKSPACE}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    echo "# Service URL: $output" >&3
}
