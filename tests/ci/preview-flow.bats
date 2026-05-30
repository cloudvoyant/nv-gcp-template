#!/usr/bin/env bats
# CI flow test: Preview environment lifecycle
# Mirrors ci.yml preview job (feature branch push)
#
# Requires GCP credentials. Set SKIP_TF_TESTS=1 to skip.
# Set SKIP_DOCKER_TESTS=1 (default) to skip docker build/push.
# Set RUN_DOCKER_TESTS=1 to include docker steps.
# Set SKIP_CLEANUP=1 to keep infra after test (for debugging).

MISE="${MISE:-$(command -v mise 2>/dev/null || echo ~/.local/bin/mise)}"

setup_file() {
    if [ -n "${SKIP_TF_TESTS:-}" ]; then
        skip "CI flow tests disabled (SKIP_TF_TESTS=1)"
    fi

    eval "$("${MISE}" env --shell bash 2>/dev/null)" || true

    if [ -z "${GCP_PROJECT_ID:-}" ] || [ -z "${GCP_DEVOPS_PROJECT_ID:-}" ]; then
        skip "GCP not configured (GCP_PROJECT_ID or GCP_DEVOPS_PROJECT_ID not set)"
    fi

    # Simulate a feature branch issue ID
    export CI_TEST_WORKSPACE="ci-test-prev-$(date +%s)"
    echo "CI_TEST_WORKSPACE=${CI_TEST_WORKSPACE}" > "${BATS_SUITE_TMPDIR}/workspace"
    echo "# Preview workspace: ${CI_TEST_WORKSPACE}" >&3

    # Ensure nonprod secret exists (required by Terraform plan) — create with placeholder if missing
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
        echo "# Destroying preview workspace: ${CI_TEST_WORKSPACE}" >&3
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
    # Use latest available web image so Cloud Run resource is provisioned.
    # RUN_DOCKER_TESTS=1 sets this from the freshly pushed image instead.
    local registry="${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev/${GCP_DEVOPS_PROJECT_ID}/${GCP_DEVOPS_DOCKER_REGISTRY_NAME}"
    export TF_VAR_app_image="${TF_VAR_app_image:-${registry}/nv-gcp-template-web:1.2.6}"
}

@test "preview: backend bucket exists or is created" {
    run "${MISE}" run tf-create-backend
    [ "$status" -eq 0 ]
}

@test "preview: install dependencies" {
    run "${MISE}" run install
    [ "$status" -eq 0 ]
}

@test "preview: build production artifacts" {
    run "${MISE}" run build-prod
    [ "$status" -eq 0 ]
}

@test "preview: publish pre-release package" {
    run "${MISE}" run publish "${CI_TEST_WORKSPACE}"
    [ "$status" -eq 0 ]
}

@test "preview: docker build (skipped unless RUN_DOCKER_TESTS=1)" {
    if [ -z "${RUN_DOCKER_TESTS:-}" ]; then
        skip "Docker tests disabled (set RUN_DOCKER_TESTS=1 to enable)"
    fi
    export DOCKER_DEFAULT_PLATFORM=linux/amd64
    run "${MISE}" run docker-build web "${CI_TEST_WORKSPACE}"
    [ "$status" -eq 0 ]
}

@test "preview: docker push (skipped unless RUN_DOCKER_TESTS=1)" {
    if [ -z "${RUN_DOCKER_TESTS:-}" ]; then
        skip "Docker tests disabled (set RUN_DOCKER_TESTS=1 to enable)"
    fi
    run "${MISE}" run docker-login
    [ "$status" -eq 0 ]
    run "${MISE}" run docker-push web "${CI_TEST_WORKSPACE}"
    [ "$status" -eq 0 ]
}

@test "preview: tf-plan succeeds" {
    run "${MISE}" run tf-plan "${CI_TEST_WORKSPACE}"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Plan:" ]] || [[ "$output" =~ "No changes" ]] || [[ "$output" =~ "Terraform will perform" ]]
}

@test "preview: tf-apply provisions infrastructure" {
    run "${MISE}" run tf-apply "${CI_TEST_WORKSPACE}" --auto-approve
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Apply complete" ]] || [[ "$output" =~ "complete!" ]]
}

@test "preview: deploy application" {
    run "${MISE}" run deploy "${CI_TEST_WORKSPACE}"
    [ "$status" -eq 0 ]
}

@test "preview: get-url returns a service URL" {
    run "${MISE}" run get-url "${CI_TEST_WORKSPACE}"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    echo "# Service URL: $output" >&3
}

@test "preview: workspace state stored in GCS" {
    BUCKET_NAME="${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage"
    EXPECTED_PATH="${GCP_PROJECT_ID}/${PROJECT}/${CI_TEST_WORKSPACE}.tfstate"
    run gsutil ls "gs://${BUCKET_NAME}/${EXPECTED_PATH}"
    [ "$status" -eq 0 ]
}
