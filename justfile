# justfile - Command runner for project automation
# Requires: just (https://github.com/casey/just)

set shell   := ["bash", "-c"]

# Dependencies
bash        := require("bash")
direnv      := require("direnv")

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

# ==============================================================================
# CORE DEVELOPMENT
# ==============================================================================

# Default recipe (show help)
_default:
    @just --list --unsorted

# Install dependencies
[group('dev')]
install:
    @echo -e "{{WARN}}TODO: Implement install{{NORMAL}}"

# Build the project
[group('dev')]
build:
    @echo -e "{{WARN}}TODO: Implement build for $_PROJECT@$VERSION{{NORMAL}}"

# Run project locally
[group('dev')]
run: build
    @echo -e "{{WARN}}TODO: Implement run{{NORMAL}}"

# Run tests
[group('dev')]
test: build
    @just test-template

# Clean build artifacts
[group('dev')]
clean:
    @rm -rf .nv
    @echo -e "{{WARN}}TODO: Implement clean{{NORMAL}}"

# ==============================================================================
# DOCKER
# ==============================================================================

[group('docker')]
docker-build:
    @COMPOSE_BAKE=true docker compose build

[group('docker')]
docker-run:
    @docker compose run --rm runner

[group('docker')]
docker-test:
    @docker compose run --rm tester

# Build and push Docker image to GCP Container Registry
[group('ci')]
docker-push TAG="{{VERSION}}": docker-build
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    IMAGE_NAME="${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev/${GCP_DEVOPS_PROJECT_ID}/${GCP_DEVOPS_DOCKER_REGISTRY_NAME}/${PROJECT}"
    LOCAL_IMAGE="${PROJECT}:{{TAG}}"

    log_info "Configuring Docker authentication for Artifact Registry..."
    gcloud auth configure-docker "${GCP_DEVOPS_PROJECT_REGION}-docker.pkg.dev" --quiet

    log_info "Pushing Docker image to GCP Container Registry..."
    log_info "Local image: ${LOCAL_IMAGE}"
    docker tag "${LOCAL_IMAGE}" "${IMAGE_NAME}:{{TAG}}"
    docker tag "${LOCAL_IMAGE}" "${IMAGE_NAME}:latest"
    docker push "${IMAGE_NAME}:{{TAG}}"
    docker push "${IMAGE_NAME}:latest"
    log_success "Image pushed: ${IMAGE_NAME}:{{TAG}}"

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
    @echo -e "{{WARN}}TODO: Implement formatting{{NORMAL}}"

# Check code formatting (CI mode)
[group('utils')]
format-check *PATHS:
    @echo -e "{{WARN}}TODO: Implement format checking{{NORMAL}}"

# Lint code
[group('utils')]
lint *PATHS:
    @echo -e "{{WARN}}TODO: Implement linting{{NORMAL}}"

# Lint and auto-fix issues
[group('utils')]
lint-fix *PATHS:
    @echo -e "{{WARN}}TODO: Implement lint auto-fixing{{NORMAL}}"

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

    cd infra/environments
    terraform plan \
        -var="project=${PROJECT}" \
        -var="gcp_project_id=${GCP_PROJECT_ID}" \
        -var="gcp_region=${GCP_REGION}" \
        -var="environment_name=${WORKSPACE_NAME}" \
        -out=tfplan

# Apply Terraform changes
[group('terraform')]
tf-apply WORKSPACE="" AUTO_APPROVE="": (tf-init WORKSPACE)
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    WORKSPACE_NAME="{{WORKSPACE}}"
    WORKSPACE_NAME="${WORKSPACE_NAME:-$(infer_terraform_workspace)}"

    cd infra/environments

    if [ "{{AUTO_APPROVE}}" = "--auto-approve" ]; then
        terraform apply -auto-approve \
            -var="project=${PROJECT}" \
            -var="gcp_project_id=${GCP_PROJECT_ID}" \
            -var="gcp_region=${GCP_REGION}" \
            -var="environment_name=${WORKSPACE_NAME}"
    else
        terraform apply \
            -var="project=${PROJECT}" \
            -var="gcp_project_id=${GCP_PROJECT_ID}" \
            -var="gcp_region=${GCP_REGION}" \
            -var="environment_name=${WORKSPACE_NAME}"
    fi

# Destroy Terraform-managed infrastructure
[group('terraform')]
tf-destroy WORKSPACE="" AUTO_APPROVE="": (tf-init WORKSPACE)
    #!/usr/bin/env bash
    set -euo pipefail
    source ./scripts/utils.sh

    WORKSPACE_NAME="{{WORKSPACE}}"
    WORKSPACE_NAME="${WORKSPACE_NAME:-$(infer_terraform_workspace)}"

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
        $([ "{{AUTO_APPROVE}}" = "--auto-approve" ] && echo "-auto-approve" || echo "")

# ==============================================================================
# CI/CD
# ==============================================================================

# Build for production
[group('ci')]
build-prod:
    @mkdir -p dist
    @echo "$PROJECT $VERSION - Replace with your build artifact" > dist/artifact.txt
    @echo -e "{{SUCCESS}}Production artifact created: dist/artifact.txt{{NORMAL}}"
    # Cross-platform build examples (uncomment and adapt as needed):
    # For Go: GOOS=linux GOARCH=amd64 go build -o dist/$PROJECT-linux-amd64
    # For Rust: cross build --target x86_64-unknown-linux-gnu --release
    # For Zig: zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSafe

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
    @bash -c scripts/upversion.sh {{ARGS}}

# Publish the project
[group('ci')]
publish: test build-prod
    #!/usr/bin/env bash
    set -euo pipefail

    # Load environment variables
    if [ -f .envrc ]; then
        source .envrc
    fi

    echo -e "{{INFO}}Publishing package $PROJECT@$VERSION{{NORMAL}}"
    gcloud artifacts generic upload \
        --project=$GCP_DEVOPS_PROJECT_ID \
        --location=$GCP_DEVOPS_PROJECT_REGION \
        --repository=$GCP_DEVOPS_REGISTRY_NAME \
        --package=$PROJECT \
        --version=$VERSION \
        --source=dist/artifact.txt
    echo -e "{{SUCCESS}}Published.{{NORMAL}}"

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

# ==============================================================================
# VS CODE
# ==============================================================================

# Hide non-essential files in VS Code
[group('vscode')]
hide:
    @bash scripts/toggle-files.sh hide

# Show all files in VS Code
[group('vscode')]
show:
    @bash scripts/toggle-files.sh show
