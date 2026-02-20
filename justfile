# justfile - Command runner for project automation
# Requires: just (https://github.com/casey/just)

set shell   := ["bash", "-c"]

# Dependencies
bash        := require("bash")

# Environment variables (auto-sourced from .envrc)
export PROJECT                  := `source .envrc && echo $PROJECT`
export VERSION                  := `source .envrc && echo $VERSION`
export GCP_PROJECT_ID           := `source .envrc && echo $GCP_PROJECT_ID`
export GCP_REGION               := `source .envrc && echo $GCP_REGION`
export GCP_DEVOPS_PROJECT_ID    := `source .envrc && echo $GCP_DEVOPS_PROJECT_ID`
export GCP_DEVOPS_PROJECT_REGION := `source .envrc && echo $GCP_DEVOPS_PROJECT_REGION`
export GCP_DEVOPS_REGISTRY_NAME := `source .envrc && echo $GCP_DEVOPS_REGISTRY_NAME`
export GCP_DEVOPS_DOCKER_REGISTRY_NAME := `source .envrc && echo $GCP_DEVOPS_DOCKER_REGISTRY_NAME`

# Color codes for output
INFO        := '\033[0;34m'
SUCCESS     := '\033[0;32m'
WARN        := '\033[1;33m'
ERROR       := '\033[0;31m'
NORMAL      := '\033[0m'

# Docker configuration
DEFAULT_SERVICE := "web"
SERVICE := env("SERVICE", DEFAULT_SERVICE)
DOCKER_TAG := env("TAG", VERSION)

# ==============================================================================
# CORE DEVELOPMENT
# ==============================================================================

# Default recipe (show help)
_default:
    @just --list --unsorted

# Install dependencies
[group('dev')]
install:
    pnpm install

# Run project locally (dev server)
[group('dev')]
dev:
    pnpm --filter @{{PROJECT}}/web dev

# Build the project
[group('dev')]
build:
    pnpm --filter @{{PROJECT}}/web build

# Run project locally (production server using built output)
[group('dev')]
run:
    node apps/web/build/index.js

# Run tests
[group('dev')]
test:
    pnpm --filter @{{PROJECT}}/web check
    @just test-template

# Clean build artifacts
[group('dev')]
clean:
    @rm -rf .nv
    @rm -rf apps/web/build
    @rm -rf apps/web/.svelte-kit
    @echo -e "{{WARN}}Cleaned build artifacts{{NORMAL}}"

# ==============================================================================
# DOCKER
# ==============================================================================

# Authenticate Docker with GCP Artifact Registry
[group('docker')]
docker-login:
    @echo -e "{{INFO}}Configuring Docker authentication for Artifact Registry...{{NORMAL}}"
    gcloud auth configure-docker {{GCP_DEVOPS_PROJECT_REGION}}-docker.pkg.dev --quiet
    @echo -e "{{SUCCESS}}Docker authenticated{{NORMAL}}"

# List available Docker services
[group('docker')]
docker-services:
    @echo -e "{{INFO}}Available services:{{NORMAL}}"
    @echo "  - web (default)"
    @echo ""
    @echo "Usage: just docker-build [SERVICE] [TAG]"
    @echo "Example: just docker-build web 1.0.0"

# Build Docker image (builds base first, then the specified service)
[group('docker')]
docker-build SERVICE=DEFAULT_SERVICE TAG="":
    #!/usr/bin/env bash
    set -euo pipefail
    ACTUAL_TAG="{{ if TAG != "" { TAG } else { VERSION } }}"
    echo -e "{{INFO}}Building base image...{{NORMAL}}"
    docker compose build base
    echo -e "{{INFO}}Building {{SERVICE}} image (tag: ${ACTUAL_TAG})...{{NORMAL}}"
    VERSION="${ACTUAL_TAG}" docker compose build {{SERVICE}}
    echo -e "{{SUCCESS}}Docker image built{{NORMAL}}"

[group('docker')]
docker-run SERVICE=DEFAULT_SERVICE:
    @docker compose up {{SERVICE}}

[group('docker')]
docker-test:
    @docker compose run --rm tester

# Build and push Docker image to GCP Artifact Registry
[group('ci')]
docker-push SERVICE=DEFAULT_SERVICE TAG="":
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    ACTUAL_TAG="{{ if TAG != "" { TAG } else { VERSION } }}"
    IMAGE_NAME="${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev/${GCP_DEVOPS_PROJECT_ID}/${GCP_DEVOPS_DOCKER_REGISTRY_NAME}/${PROJECT}-{{SERVICE}}:${ACTUAL_TAG}"

    echo -e "{{INFO}}Building and pushing {{SERVICE}} (tag: ${ACTUAL_TAG})...{{NORMAL}}"
    docker compose build base
    VERSION="${ACTUAL_TAG}" docker compose build {{SERVICE}}
    VERSION="${ACTUAL_TAG}" docker compose push {{SERVICE}}

    mkdir -p .nv
    echo "${IMAGE_NAME}" > .nv/docker-image.txt
    echo -e "{{SUCCESS}}Docker image pushed: ${IMAGE_NAME}{{NORMAL}}"

# ==============================================================================
# UTILITIES
# ==============================================================================

# Setup development environment
[group('utils')]
setup *ARGS:
    @bash scripts/setup.sh {{ARGS}}

# Format code
[group('utils')]
format *PATHS:
    pnpm prettier --write ${PATHS:-.}

# Check code formatting (CI mode)
[group('utils')]
format-check *PATHS:
    pnpm prettier --check ${PATHS:-.}

# Lint code (type check)
[group('utils')]
lint *PATHS:
    pnpm --filter @{{PROJECT}}/web check

# Lint and auto-fix issues
[group('utils')]
lint-fix *PATHS:
    pnpm prettier --write ${PATHS:-.}

# Upgrade to newer template version (requires Claude Code)
[group('utils')]
upgrade:
    #!/usr/bin/env bash
    if command -v claude >/dev/null 2>&1; then
        if grep -q "NV_TEMPLATE=" .envrc 2>/dev/null; then
            claude /upgrade;
        else
            echo -e "{{ERROR}}This project is not based on a template{{NORMAL}}";
            echo "";
            echo "To adopt a template, use the nv CLI:";
            echo "  nv scaffold <template>";
            exit 1;
        fi;
    else
        echo -e "{{ERROR}}Claude Code CLI not found{{NORMAL}}";
        echo "Install Claude Code or run: /upgrade";
        exit 1;
    fi

# Authenticate with GCP (local: gcloud login, CI: service account)
[group('utils')]
gcp-login *ARGS:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ " {{ARGS}} " =~ " --ci " ]]; then
        echo -e "{{INFO}}CI mode - authenticating with service account{{NORMAL}}"
        KEY_FILE=$(mktemp)
        echo "$GCP_SA_KEY" > "$KEY_FILE"
        gcloud auth activate-service-account --key-file="$KEY_FILE"
        rm -f "$KEY_FILE"
        gcloud config set project "$GCP_DEVOPS_PROJECT_ID"
    else
        echo -e "{{INFO}}Local mode - interactive GCP login{{NORMAL}}"
        gcloud auth login
        gcloud config set project "$GCP_DEVOPS_PROJECT_ID"
    fi

# ==============================================================================
# TERRAFORM
# ==============================================================================

# Create GCS backend bucket for Terraform state (shared across all projects)
[group('terraform')]
tf-create-backend:
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    BUCKET_NAME="${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage"

    log_info "Checking for shared GCS backend bucket: ${BUCKET_NAME}"

    if gsutil ls -b "gs://${BUCKET_NAME}" > /dev/null 2>&1; then
        log_success "Backend bucket already exists: ${BUCKET_NAME}"
    else
        log_info "Creating shared tfstate bucket in DevOps project..."
        gsutil mb -p "${GCP_DEVOPS_PROJECT_ID}" -l "${GCP_DEVOPS_PROJECT_REGION}" "gs://${BUCKET_NAME}"
        gsutil versioning set on "gs://${BUCKET_NAME}"
        log_success "Backend bucket created: ${BUCKET_NAME}"
    fi

# List all Terraform workspaces
[group('terraform')]
tf-list-workspaces:
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    log_info "Listing Terraform workspaces..."
    cd infra/environments
    terraform workspace list

# Create/select Terraform workspace (auto-infers from branch or accepts explicit workspace)
[group('terraform')]
tf-select-workspace WORKSPACE="":
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    WORKSPACE_NAME="{{WORKSPACE}}"
    if [ -z "$WORKSPACE_NAME" ]; then
        WORKSPACE_NAME="$(infer_terraform_workspace)"
        log_info "Auto-detected workspace from branch: ${WORKSPACE_NAME}"
    else
        log_info "Using explicit workspace: ${WORKSPACE_NAME}"
    fi

    cd infra/environments

    # Check if workspace exists
    if terraform workspace list | grep -q "^[* ]*${WORKSPACE_NAME}$"; then
        log_info "Selecting existing workspace: ${WORKSPACE_NAME}"
        terraform workspace select "${WORKSPACE_NAME}"
    else
        log_info "Creating new workspace: ${WORKSPACE_NAME}"
        terraform workspace new "${WORKSPACE_NAME}"
    fi

    log_success "Active workspace: ${WORKSPACE_NAME}"

# Initialize Terraform backend and select workspace
[group('terraform')]
tf-init WORKSPACE="":
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    WORKSPACE_NAME="{{WORKSPACE}}"
    WORKSPACE_NAME="${WORKSPACE_NAME:-$(infer_terraform_workspace)}"
    BUCKET_NAME="${GCP_DEVOPS_PROJECT_ID}-terraform-backend-storage"
    PREFIX="${GCP_PROJECT_ID}/${PROJECT}"

    # Check if backend bucket exists
    if ! gsutil ls -b "gs://${BUCKET_NAME}" > /dev/null 2>&1; then
        log_error "Backend bucket does not exist: ${BUCKET_NAME}"
        log_error "Run 'just tf-create-backend' to create the necessary GCS backend bucket"
        exit 1
    fi

    log_info "Initializing Terraform backend..."
    log_info "Bucket: ${BUCKET_NAME}"
    log_info "Prefix: ${PREFIX}"
    log_info "Workspace: ${WORKSPACE_NAME}"

    cd infra/environments
    terraform init \
        -backend-config="bucket=${BUCKET_NAME}" \
        -backend-config="prefix=${PREFIX}" \
        -reconfigure

    # Select or create workspace
    select_terraform_workspace "${WORKSPACE_NAME}" "."

    log_success "Terraform initialized for workspace: ${WORKSPACE_NAME}"
    log_success "State: gs://${BUCKET_NAME}/${PREFIX}/env:/${WORKSPACE_NAME}/default.tfstate"

# Run Terraform plan
[group('terraform')]
tf-plan WORKSPACE="": (tf-init WORKSPACE)
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    WORKSPACE_NAME="{{WORKSPACE}}"
    WORKSPACE_NAME="${WORKSPACE_NAME:-$(infer_terraform_workspace)}"

    # Use TF_VAR_app_image if set by CI (docker push step). Leave empty otherwise
    # so Cloud Run is not deployed without a valid image.
    APP_IMAGE="${TF_VAR_app_image:-}"

    cd infra/environments
    terraform plan \
        -var="project=${PROJECT}" \
        -var="gcp_project_id=${GCP_PROJECT_ID}" \
        -var="gcp_region=${GCP_REGION}" \
        -var="environment_name=${WORKSPACE_NAME}" \
        -var="gcp_devops_project_id=${GCP_DEVOPS_PROJECT_ID}" \
        -var="gcp_devops_docker_registry_name=${GCP_DEVOPS_DOCKER_REGISTRY_NAME}" \
        -var="gcp_devops_project_region=${GCP_DEVOPS_PROJECT_REGION}" \
        -var="app_image=${APP_IMAGE}" \
        -out=tfplan

# Apply Terraform changes
[group('terraform')]
tf-apply WORKSPACE="" AUTO_APPROVE="": (tf-init WORKSPACE)
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    WORKSPACE_NAME="{{WORKSPACE}}"
    WORKSPACE_NAME="${WORKSPACE_NAME:-$(infer_terraform_workspace)}"

    # Use TF_VAR_app_image if set by CI (docker push step). Leave empty otherwise
    # so Cloud Run is not deployed without a valid image.
    APP_IMAGE="${TF_VAR_app_image:-}"

    cd infra/environments

    if [ "{{AUTO_APPROVE}}" = "--auto-approve" ]; then
        terraform apply -auto-approve \
            -var="project=${PROJECT}" \
            -var="gcp_project_id=${GCP_PROJECT_ID}" \
            -var="gcp_region=${GCP_REGION}" \
            -var="environment_name=${WORKSPACE_NAME}" \
            -var="gcp_devops_project_id=${GCP_DEVOPS_PROJECT_ID}" \
            -var="gcp_devops_docker_registry_name=${GCP_DEVOPS_DOCKER_REGISTRY_NAME}" \
            -var="gcp_devops_project_region=${GCP_DEVOPS_PROJECT_REGION}" \
            -var="app_image=${APP_IMAGE}"
    else
        terraform apply \
            -var="project=${PROJECT}" \
            -var="gcp_project_id=${GCP_PROJECT_ID}" \
            -var="gcp_region=${GCP_REGION}" \
            -var="environment_name=${WORKSPACE_NAME}" \
            -var="gcp_devops_project_id=${GCP_DEVOPS_PROJECT_ID}" \
            -var="gcp_devops_docker_registry_name=${GCP_DEVOPS_DOCKER_REGISTRY_NAME}" \
            -var="gcp_devops_project_region=${GCP_DEVOPS_PROJECT_REGION}" \
            -var="app_image=${APP_IMAGE}"
    fi

# Destroy Terraform-managed infrastructure
[group('terraform')]
tf-destroy WORKSPACE="" AUTO_APPROVE="": (tf-init WORKSPACE)
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    WORKSPACE_NAME="{{WORKSPACE}}"
    WORKSPACE_NAME="${WORKSPACE_NAME:-$(infer_terraform_workspace)}"

    # Use TF_VAR_app_image if set, otherwise empty (Cloud Run not provisioned without an image)
    APP_IMAGE="${TF_VAR_app_image:-}"

    log_warn "WARNING: This will destroy all infrastructure in workspace: ${WORKSPACE_NAME}"

    if [ "{{AUTO_APPROVE}}" != "--auto-approve" ]; then
        if ! confirm "Are you sure you want to destroy this infrastructure?"; then
            log_info "Destroy cancelled"
            exit 0
        fi
    fi

    cd infra/environments
    terraform destroy \
        -var="project=${PROJECT}" \
        -var="gcp_project_id=${GCP_PROJECT_ID}" \
        -var="gcp_region=${GCP_REGION}" \
        -var="environment_name=${WORKSPACE_NAME}" \
        -var="gcp_devops_project_id=${GCP_DEVOPS_PROJECT_ID}" \
        -var="gcp_devops_docker_registry_name=${GCP_DEVOPS_DOCKER_REGISTRY_NAME}" \
        -var="gcp_devops_project_region=${GCP_DEVOPS_PROJECT_REGION}" \
        -var="app_image=${APP_IMAGE}" \
        $([ "{{AUTO_APPROVE}}" = "--auto-approve" ] && echo "-auto-approve" || echo "")

# ==============================================================================
# CI/CD
# ==============================================================================

# Build for production
[group('ci')]
build-prod:
    pnpm --filter @{{PROJECT}}/web build

# Get service URL for a deployed environment
get-url WORKSPACE="":
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh
    WORKSPACE_NAME="{{WORKSPACE}}"
    WORKSPACE_NAME="${WORKSPACE_NAME:-$(infer_terraform_workspace)}"
    cd infra/environments
    terraform workspace select "${WORKSPACE_NAME}" >/dev/null 2>&1
    terraform output -raw app_public_url

# Force Cloud Run to redeploy current image (useful when image tag unchanged)
force-redeploy WORKSPACE="":
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh
    WORKSPACE_NAME="{{WORKSPACE}}"
    WORKSPACE_NAME="${WORKSPACE_NAME:-$(infer_terraform_workspace)}"

    if [ "$WORKSPACE_NAME" = "prod" ]; then
        SERVICE_NAME="${PROJECT}-prod"
    else
        SERVICE_NAME="${PROJECT}-${WORKSPACE_NAME}"
    fi

    CURRENT_IMAGE=$(gcloud run services describe "${SERVICE_NAME}" \
        --project="${GCP_PROJECT_ID}" \
        --region="${GCP_REGION}" \
        --format="value(spec.template.spec.containers[0].image)")

    gcloud run services update "${SERVICE_NAME}" \
        --image="${CURRENT_IMAGE}" \
        --region="${GCP_REGION}" \
        --project="${GCP_PROJECT_ID}"
    log_success "Service redeployed successfully"

# Get current version
[group('ci')]
version:
    @echo "$VERSION"

# Get next version (from semantic-release)
[group('ci')]
version-next:
    @bash -c 'source scripts/utils.sh && get_next_version'

# Create new version based on commits (semantic-release)
[group('ci')]
upversion *ARGS:
    @bash scripts/upversion.sh {{ARGS}}

# Publish the project
[group('ci')]
publish TAG="":
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    # Load environment variables
    if [ -f .envrc ]; then
        source .envrc
    fi

    # Construct package version
    PUBLISH_VERSION="{{TAG}}"
    if [ -n "$PUBLISH_VERSION" ]; then
        # Pre-release: use next version with RC tag and commit hash (e.g., 1.2.4-rc.nv-29.abc1234)
        NEXT_VERSION=$(get_next_version)
        if [ -z "$NEXT_VERSION" ]; then
            log_error "Could not determine next version"
            exit 1
        fi
        COMMIT_HASH=$(git rev-parse --short HEAD)
        PUBLISH_VERSION="${NEXT_VERSION}-rc.${PUBLISH_VERSION}.${COMMIT_HASH}"
        log_info "Publishing pre-release package: ${PROJECT}@${PUBLISH_VERSION}"
    else
        # Release: use version from version.txt
        PUBLISH_VERSION="${VERSION}"
        log_info "Publishing release package: ${PROJECT}@${PUBLISH_VERSION}"
    fi

    gcloud artifacts generic upload \
        --project=$GCP_DEVOPS_PROJECT_ID \
        --location=$GCP_DEVOPS_PROJECT_REGION \
        --repository=$GCP_DEVOPS_REGISTRY_NAME \
        --package=$PROJECT \
        --version=$PUBLISH_VERSION \
        --source=dist/artifact.txt

    log_success "Published: ${PROJECT}@${PUBLISH_VERSION}"

# Deploy application after infrastructure is provisioned
[group('ci')]
deploy WORKSPACE="":
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    WORKSPACE_NAME="{{WORKSPACE}}"
    WORKSPACE_NAME="${WORKSPACE_NAME:-$(infer_terraform_workspace)}"

    log_info "Running post-infrastructure deployment for workspace: ${WORKSPACE_NAME}"
    log_info "Add application deployment steps here (kubectl apply, gcloud run deploy, etc.)"
    # Example: kubectl apply -f k8s/ --context=${WORKSPACE_NAME}

# ==============================================================================
# VS Code and Zed
# ==============================================================================

# Hide non-essential files in VS Code / Zed
[group('utils')]
hide:
    @bash scripts/toggle-files.sh hide

# Show all files in VS Code / Zed
[group('utils')]
show:
    @bash scripts/toggle-files.sh show

# ==============================================================================
# TEMPLATE
# ==============================================================================

# Scaffold a new project
[group('template')]
scaffold:
    @bash scripts/scaffold.sh

# Run template tests
[group('template')]
test-template:
    #!/usr/bin/env bash
    if command -v bats >/dev/null 2>&1; then
        echo -e "{{INFO}}Running template tests{{NORMAL}}";
        # Use parallel execution if GNU parallel is available
        if command -v parallel >/dev/null 2>&1; then
            find test/ -name "*.bats" -print0 | parallel -0 -j+0 bats {};
        else
            bats test/;
        fi
    else
        echo -e "{{ERROR}}bats not installed. Run: just setup --template{{NORMAL}}";
        exit 1;
    fi
