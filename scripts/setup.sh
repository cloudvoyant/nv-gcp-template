#!/usr/bin/env bash
: <<DOCUMENTATION
Installs development dependencies for this platform.

Usage: setup.sh [OPTIONS]

Options:
  --dev              Install development tools (docker, shellcheck, shfmt, claude)
  --ci               Install CI essentials (node/npx, gcloud)
  --template         Install template development tools (bats-core)
  --starship         Install and configure starship prompt
  --docker-optimize  Optimize for Docker image size (consolidate operations, aggressive cleanup)

Flags can be combined: setup.sh --dev --template --starship --docker-optimize

Required dependencies (always installed):
- bash (shell)
- just (command runner)
- direnv (environment management)

Development tools (--dev):
- docker (containerization)
- node/npx (for semantic-release)
- gcloud (Google Cloud SDK)
- shellcheck (shell script linter)
- shfmt (shell script formatter)
- claude (Claude CLI)
- claudevoyant plugin (slash commands for Claude)

CI essentials (--ci):
- node/npx (for semantic-release)
- gcloud (Google Cloud SDK)
- bats-core (bash testing framework)
- parallel (parallel test execution)

Template development (--template):
- bats-core (bash testing framework)
- parallel (parallel test execution)
DOCUMENTATION

# IMPORTS ----------------------------------------------------------------------
source "$(dirname "$0")/utils.sh"
set -euo pipefail

# ARGUMENT PARSING -------------------------------------------------------------

INSTALL_DEV=false
INSTALL_CI=false
INSTALL_TEMPLATE=false
INSTALL_STARSHIP=false
DOCKER_OPTIMIZE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            INSTALL_DEV=true
            shift
            ;;
        --ci)
            INSTALL_CI=true
            shift
            ;;
        --template)
            INSTALL_TEMPLATE=true
            shift
            ;;
        --starship)
            INSTALL_STARSHIP=true
            shift
            ;;
        --docker-optimize)
            DOCKER_OPTIMIZE=true
            shift
            ;;
        -h|--help)
            echo "Usage: setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dev         Install development tools"
            echo "  --ci          Install CI essentials"
            echo "  --template    Install template development tools"
            echo "  -h, --help    Show this help message"
            echo ""
            echo "Required: bash, just, direnv"
            echo "Development (--dev): docker, node/npx, gcloud, shellcheck, shfmt, claude, claudevoyant plugin"
            echo "CI (--ci): docker, node/npx, gcloud"
            echo "Template (--template): bats-core"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Run 'setup.sh --help' for usage"
            exit 1
            ;;
    esac
done

# DEPENDENCY CHECKING ----------------------------------------------------------

# Detect OS platform
detect_platform() {
    case "$(uname -s)" in
    Linux*) PLATFORM=Linux ;;
    Darwin*) PLATFORM=Mac ;;
    CYGWIN*) PLATFORM=Cygwin ;;
    MINGW*) PLATFORM=MinGw ;;
    MSYS*) PLATFORM=Git ;;
    *) PLATFORM="UNKNOWN:${unameOut}" ;;
    esac
    log_info "Detected platform: $PLATFORM"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install bash based on platform
install_bash() {
    log_info "Installing Bash"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install bash
        else
            log_warn "Homebrew not found. Please install Bash manually"
            return 1
        fi
        ;;
    Linux)
        if command_exists apk; then
            sudo apk add --no-cache bash
        elif command_exists apt-get; then
            sudo apt-get install -y --no-install-recommends bash
        elif command_exists yum; then
            sudo yum install -y bash
        elif command_exists pacman; then
            sudo pacman -S bash
        else
            log_warn "Unsupported Linux distribution. Please install Bash manually"
            return 1
        fi
        ;;
    *)
        log_warn "Unsupported platform for automatic Bash installation. Please install Bash manually"
        return 1
        ;;
    esac

    log_success "Bash installation completed"
}

# Install just based on platform
install_just() {
    log_info "Installing just"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install just
        else
            log_warn "Homebrew not found. Installing just from binary"
            curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/bin
            log_info "Add ~/bin to your PATH if not already present"
        fi
        ;;
    Linux)
        if command_exists cargo; then
            cargo install just
        elif command_exists apt-get; then
            # Install from binary for latest version
            curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin
        else
            log_warn "Installing just from binary"
            curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/bin
            log_info "Add ~/bin to your PATH if not already present"
        fi
        ;;
    *)
        log_warn "Unsupported platform for automatic just installation. Please install just manually from https://just.systems"
        return 1
        ;;
    esac

    log_success "just installation completed"
}

# Install Docker based on platform
install_docker() {
    log_info "Installing Docker"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install --cask docker
        else
            log_warn "Homebrew not found. Please install Docker Desktop manually from https://docker.com/products/docker-desktop"
            return 1
        fi
        ;;
    Linux)
        if command_exists apk; then
            sudo apk add --no-cache docker docker-compose
            sudo rc-update add docker boot 2>/dev/null || true
            sudo service docker start 2>/dev/null || true
        elif command_exists apt-get; then
            sudo apt-get install -y --no-install-recommends docker.io docker-compose
            sudo systemctl start docker
            sudo systemctl enable docker
        elif command_exists yum; then
            sudo yum install -y docker docker-compose
            sudo systemctl start docker
            sudo systemctl enable docker
        elif command_exists pacman; then
            sudo pacman -S docker docker-compose
            sudo systemctl start docker
            sudo systemctl enable docker
        else
            log_warn "Unsupported Linux distribution. Please install Docker manually from https://docs.docker.com/engine/install/"
            return 1
        fi
        ;;
    *)
        log_warn "Unsupported platform for automatic Docker installation. Please install Docker manually from https://docker.com"
        return 1
        ;;
    esac

    log_success "Docker installation completed"
}

# Install direnv based on platform
install_direnv() {
    log_info "Installing direnv"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install direnv
        else
            log_warn "Homebrew not found. Please install direnv manually from https://direnv.net/docs/installation.html"
            return 1
        fi
        ;;
    Linux)
        # Try binary installation first (recommended by direnv)
        if command_exists curl; then
            log_info "Installing direnv from binary release"
            curl -sfL https://direnv.net/install.sh | bash
        elif command_exists apk; then
            sudo apk add --no-cache direnv
        elif command_exists apt-get; then
            sudo apt-get install -y --no-install-recommends direnv
        elif command_exists yum; then
            sudo yum install -y direnv
        elif command_exists pacman; then
            sudo pacman -S direnv
        else
            log_warn "curl not found and no suitable package manager found. Please install direnv manually from https://direnv.net/docs/installation.html"
            return 1
        fi
        ;;
    *)
        log_warn "Unsupported platform for automatic direnv installation. Please install direnv manually from https://direnv.net/docs/installation.html"
        return 1
        ;;
    esac

    log_success "direnv installation completed"
    log_info "Please add 'eval \"\$(direnv hook bash)\"' to your ~/.bashrc or shell config"
}

# Install Node.js and npx based on platform
install_node() {
    log_info "Installing Node.js"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install node
        else
            log_warn "Homebrew not found. Please install Node.js manually from https://nodejs.org"
            return 1
        fi
        ;;
    Linux)
        if command_exists apk; then
            sudo apk add --no-cache nodejs npm
        elif command_exists apt-get; then
            sudo apt-get install -y --no-install-recommends nodejs npm
        elif command_exists yum; then
            sudo yum install -y nodejs npm
        elif command_exists pacman; then
            sudo pacman -S nodejs npm
        else
            log_warn "No suitable package manager found. Please install Node.js manually from https://nodejs.org"
            return 1
        fi
        ;;
    *)
        log_warn "Unsupported platform for automatic Node.js installation. Please install Node.js manually from https://nodejs.org"
        return 1
        ;;
    esac

    log_success "Node.js installation completed"
}

# Install gcloud based on platform
install_gcloud() {
    log_info "Installing Google Cloud SDK"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install --cask google-cloud-sdk
        else
            log_warn "Homebrew not found. Please install gcloud manually from https://cloud.google.com/sdk/docs/install"
            return 1
        fi
        ;;
    Linux)
        # Detect architecture
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64)  ARCH_SUFFIX="x86_64" ;;
            aarch64) ARCH_SUFFIX="arm" ;;
            arm64)   ARCH_SUFFIX="arm" ;;
            *)
                log_error "Unsupported architecture for gcloud: $ARCH"
                return 1
                ;;
        esac

        if command_exists apk; then
            # Alpine doesn't have official gcloud package, install from tarball
            log_info "Installing gcloud from official tarball (${ARCH_SUFFIX})"
            if ! command_exists python3; then
                sudo apk add --no-cache python3 py3-pip
            fi
            curl -O "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-${ARCH_SUFFIX}.tar.gz"
            tar -xf "google-cloud-cli-linux-${ARCH_SUFFIX}.tar.gz"
            sudo ./google-cloud-sdk/install.sh --quiet --install-dir=/usr/local
            rm -rf google-cloud-sdk "google-cloud-cli-linux-${ARCH_SUFFIX}.tar.gz"
            # Add to PATH
            echo 'export PATH=$PATH:/usr/local/google-cloud-sdk/bin' | sudo tee -a /etc/profile.d/gcloud.sh
        elif command_exists apt-get; then
            # Add gcloud apt repository
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

            # Import Google Cloud public key (modern method, not apt-key)
            if command_exists curl; then
                curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
            else
                log_error "curl is required to install gcloud"
                return 1
            fi

            # Update package list (unless docker-optimize is set)
            if [ "$DOCKER_OPTIMIZE" = false ]; then
                sudo apt-get update
            fi

            # Install gcloud
            sudo apt-get install -y --no-install-recommends google-cloud-sdk
        elif command_exists yum; then
            # Add gcloud yum repository
            sudo tee /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM
            sudo yum install -y google-cloud-sdk
        else
            log_warn "No suitable package manager found. Please install gcloud manually from https://cloud.google.com/sdk/docs/install"
            return 1
        fi
        ;;
    *)
        log_warn "Unsupported platform for automatic gcloud installation. Please install gcloud manually from https://cloud.google.com/sdk/docs/install"
        return 1
        ;;
    esac

    log_success "Google Cloud SDK installation completed"
}

# Install shellcheck based on platform
install_shellcheck() {
    log_info "Installing shellcheck"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install shellcheck
        else
            log_warn "Homebrew not found. Please install shellcheck manually from https://www.shellcheck.net"
            return 1
        fi
        ;;
    Linux)
        if command_exists apk; then
            sudo apk add --no-cache shellcheck
        elif command_exists apt-get; then
            sudo apt-get install -y --no-install-recommends shellcheck
        elif command_exists yum; then
            sudo yum install -y ShellCheck
        elif command_exists pacman; then
            sudo pacman -S shellcheck
        else
            log_warn "No suitable package manager found. Please install shellcheck manually from https://www.shellcheck.net"
            return 1
        fi
        ;;
    *)
        log_warn "Unsupported platform for automatic shellcheck installation. Please install shellcheck manually from https://www.shellcheck.net"
        return 1
        ;;
    esac

    log_success "shellcheck installation completed"
}

# Install shfmt based on platform
install_shfmt() {
    log_info "Installing shfmt"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install shfmt
        else
            log_warn "Homebrew not found. Please install shfmt manually from https://github.com/mvdan/sh"
            return 1
        fi
        ;;
    Linux)
        if command_exists go; then
            go install mvdan.cc/sh/v3/cmd/shfmt@latest
        else
            log_warn "Go not found. Installing shfmt from binary"
            ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
            curl -L "https://github.com/mvdan/sh/releases/latest/download/shfmt_v3_linux_${ARCH}" -o /tmp/shfmt
            chmod +x /tmp/shfmt
            sudo mv /tmp/shfmt /usr/local/bin/shfmt
        fi
        ;;
    *)
        log_warn "Unsupported platform for automatic shfmt installation. Please install shfmt manually from https://github.com/mvdan/sh"
        return 1
        ;;
    esac

    log_success "shfmt installation completed"
}

# Install bats-core based on platform
install_bats() {
    log_info "Installing bats-core"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install bats-core
        else
            log_warn "Homebrew not found. Please install bats-core manually from https://github.com/bats-core/bats-core"
            return 1
        fi
        ;;
    Linux)
        if command_exists apk; then
            sudo apk add --no-cache bats
        elif command_exists apt-get; then
            sudo apt-get install -y --no-install-recommends bats
        elif command_exists yum; then
            sudo yum install -y bats
        else
            log_warn "Installing bats-core from source"
            git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
            cd /tmp/bats-core || return 1
            sudo ./install.sh /usr/local
            cd - > /dev/null || return 1
            rm -rf /tmp/bats-core
        fi
        ;;
    *)
        log_warn "Unsupported platform for automatic bats-core installation. Please install bats-core manually from https://github.com/bats-core/bats-core"
        return 1
        ;;
    esac

    log_success "bats-core installation completed"
}

# Install GNU parallel based on platform
install_parallel() {
    log_info "Installing GNU parallel"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install parallel
        else
            log_warn "Homebrew not found. Please install GNU parallel manually"
            return 1
        fi
        ;;
    Linux)
        if command_exists apk; then
            sudo apk add --no-cache parallel
        elif command_exists apt-get; then
            sudo apt-get install -y --no-install-recommends parallel
        elif command_exists yum; then
            sudo yum install -y parallel
        elif command_exists pacman; then
            sudo pacman -S parallel
        else
            log_warn "No suitable package manager found. Please install GNU parallel manually"
            return 1
        fi
        ;;
    *)
        log_warn "Unsupported platform for automatic GNU parallel installation"
        return 1
        ;;
    esac

    log_success "GNU parallel installation completed"
}

# Install starship based on platform
install_starship() {
    log_info "Installing starship"

    case $PLATFORM in
    Mac)
        if command_exists brew; then
            brew install starship
        else
            log_warn "Homebrew not found. Installing starship from script"
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
        ;;
    Linux)
        log_info "Installing starship from official installer"
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        ;;
    *)
        log_warn "Unsupported platform for automatic starship installation"
        return 1
        ;;
    esac

    log_success "starship installation completed"
}

# Configure starship for dev containers
configure_starship() {
    log_info "Configuring starship"

    # Create starship config directory
    mkdir -p ~/.config

    # Create minimal starship configuration
    cat > ~/.config/starship.toml <<'EOF'
# Starship configuration for dev containers
format = """
[┌───────────────────────────────────────────────────────────>](bold green)
[│](bold green)$directory$git_branch$git_status
[└─>](bold green) """

[directory]
style = "blue bold"
truncation_length = 4
truncate_to_repo = false

[git_branch]
style = "yellow bold"
format = " on [$symbol$branch]($style)"

[git_status]
style = "red bold"
format = '([\[$all_status$ahead_behind\]]($style))'
EOF

    log_success "starship configuration created"
}

# Install Claude CLI based on platform
install_claude() {
    log_info "Installing Claude CLI"

    # Claude CLI requires Node.js and npm
    if ! command_exists npm; then
        log_error "npm is required to install Claude CLI"
        return 1
    fi

    # Install Claude CLI globally via npm
    npm install -g @anthropic-ai/claude-cli 2>&1 | grep -v "npm WARN" || true

    log_success "Claude CLI installation completed"
}

# Install Claudevoyant plugin for Claude CLI
install_claudevoyant_plugin() {
    log_info "Installing Claudevoyant plugin"

    # Check if Claude CLI is installed
    if ! command_exists claude; then
        log_warn "Claude CLI not found - skipping plugin installation"
        return 1
    fi

    # Add marketplace if not already added (suppress error if already exists)
    claude plugin marketplace add cloudvoyant/claudevoyant 2>&1 | grep -v "already installed" || true

    # Install plugin from marketplace
    if claude plugin install claudevoyant 2>&1 | grep -v "^$"; then
        log_success "Claudevoyant plugin installed successfully"
    else
        log_warn "Failed to install Claudevoyant plugin - you can install it manually with 'claude plugin install claudevoyant'"
        return 1
    fi
}

# Check and install dependencies
check_dependencies() {
    log_info "Checking dependencies"
    log_info "Required: bash, just, direnv"

    if [ "$INSTALL_DEV" = true ]; then
        log_info "Development tools: docker, node/npx, gcloud, shellcheck, shfmt, claude, claudevoyant plugin (will be installed)"
    fi
    if [ "$INSTALL_CI" = true ]; then
        log_info "CI essentials: node/npx, gcloud, bats-core, parallel (will be installed)"
    fi
    if [ "$INSTALL_TEMPLATE" = true ]; then
        log_info "Template development: bats-core, parallel (will be installed)"
    fi
    if [ "$INSTALL_DEV" = false ] && [ "$INSTALL_CI" = false ] && [ "$INSTALL_TEMPLATE" = false ]; then
        log_info "Optional tools: skipped (use --dev, --ci, or --template flags to install)"
    fi
    echo ""

    # Run package manager update once at the beginning (for Linux systems)
    # Skip if --docker-optimize is set (reduces layer size)
    if [ "$PLATFORM" = "Linux" ] && [ "$DOCKER_OPTIMIZE" = false ]; then
        if command_exists apk; then
            log_info "Updating package lists"
            sudo apk update
        elif command_exists apt-get; then
            log_info "Updating package lists"
            sudo apt-get update
        fi
    fi

    local current=0
    local failed_required=0

    # REQUIRED DEPENDENCIES --------------------------------------------------------

    # Check Bash (REQUIRED)
    current=$((current + 1))
    progress_step $current "Checking Bash (required)"
    if command_exists bash; then
        log_success "Bash is already installed: $(bash --version | head -n1)"
    else
        log_warn "Bash not found"
        if install_bash; then
            log_success "Bash installed successfully"
        else
            log_error "Failed to install Bash - please install manually and re-run setup"
            failed_required=1
        fi
    fi

    # Check just (REQUIRED)
    current=$((current + 1))
    progress_step $current "Checking just (required)"
    if command_exists just; then
        log_success "just is already installed: $(just --version)"
    else
        log_warn "just not found"
        if install_just; then
            log_success "just installed successfully"
        else
            log_error "Failed to install just - visit https://just.systems to install manually and re-run setup"
            failed_required=1
        fi
    fi

    # Check direnv (REQUIRED)
    current=$((current + 1))
    progress_step $current "Checking direnv (required)"
    if command_exists direnv; then
        log_success "direnv is already installed: $(direnv --version)"
    else
        log_warn "direnv not found"
        if install_direnv; then
            log_success "direnv installed successfully"
        else
            log_error "Failed to install direnv - visit https://direnv.net to install manually and re-run setup"
            failed_required=1
        fi
    fi

    # Exit if any required dependencies failed
    if [ $failed_required -eq 1 ]; then
        log_error "Required dependencies are missing. Please install them and re-run setup."
        exit 1
    fi

    # OPTIONAL DEPENDENCIES --------------------------------------------------------

    # Check Docker (for --dev only)
    if [ "$INSTALL_DEV" = true ]; then
        current=$((current + 1))
        progress_step $current "Checking Docker"
        if command_exists docker; then
            log_success "Docker is already installed: $(docker --version)"
        else
            log_warn "Docker not found (needed for containerization)"
            if install_docker; then
                log_success "Docker installed successfully"
            else
                log_warn "Skipping Docker - install manually from https://docker.com if needed"
            fi
        fi
    fi

    # Check Node.js and npx (for --dev or --ci)
    if [ "$INSTALL_DEV" = true ] || [ "$INSTALL_CI" = true ]; then
        current=$((current + 1))
        progress_step $current "Checking Node.js and npx"
        if command_exists npx; then
            log_success "Node.js and npx are already installed: $(node --version)"
        else
            log_warn "Node.js/npx not found (needed for semantic-release)"
            if install_node; then
                log_success "Node.js installed successfully"
            else
                log_warn "Skipping Node.js - install manually from https://nodejs.org if needed"
            fi
        fi

        # Install semantic-release and required plugins if npx is available
        if command_exists npx; then
            current=$((current + 1))
            progress_step $current "Installing semantic-release plugins"
            log_info "Installing semantic-release and plugins"

            # Install globally to avoid needing package.json in every project
            npm install -g semantic-release \
                @semantic-release/changelog \
                @semantic-release/exec \
                @semantic-release/git \
                conventional-changelog-conventionalcommits 2>&1 | grep -v "npm WARN" || true

            log_success "semantic-release plugins installed"
        fi
    fi

    # Check gcloud (for --dev or --ci)
    if [ "$INSTALL_DEV" = true ] || [ "$INSTALL_CI" = true ]; then
        current=$((current + 1))
        progress_step $current "Checking Google Cloud SDK"
        if command_exists gcloud; then
            log_success "Google Cloud SDK is already installed: $(gcloud --version | head -n1)"
        else
            log_warn "gcloud not found (needed for GCP Artifact Registry)"
            if install_gcloud; then
                log_success "Google Cloud SDK installed successfully"
            else
                log_warn "Skipping gcloud - install manually from https://cloud.google.com/sdk/docs/install if needed"
            fi
        fi
    fi

    # Check shellcheck (for --dev only)
    if [ "$INSTALL_DEV" = true ]; then
        current=$((current + 1))
        progress_step $current "Checking shellcheck"
        if command_exists shellcheck; then
            log_success "shellcheck is already installed: $(shellcheck --version | head -n2 | tail -n1)"
        else
            log_warn "shellcheck not found (recommended for shell script linting)"
            if install_shellcheck; then
                log_success "shellcheck installed successfully"
            else
                log_warn "Skipping shellcheck - install manually from https://www.shellcheck.net if needed"
            fi
        fi
    fi

    # Check shfmt (for --dev only)
    if [ "$INSTALL_DEV" = true ]; then
        current=$((current + 1))
        progress_step $current "Checking shfmt"
        if command_exists shfmt; then
            log_success "shfmt is already installed: $(shfmt --version)"
        else
            log_warn "shfmt not found (recommended for shell script formatting)"
            if install_shfmt; then
                log_success "shfmt installed successfully"
            else
                log_warn "Skipping shfmt - install manually from https://github.com/mvdan/sh if needed"
            fi
        fi
    fi

    # Check Claude CLI (for --dev only)
    if [ "$INSTALL_DEV" = true ]; then
        current=$((current + 1))
        progress_step $current "Checking Claude CLI"
        if command_exists claude; then
            log_success "Claude CLI is already installed: $(claude --version 2>/dev/null || echo 'version unknown')"
        else
            log_warn "Claude CLI not found (AI-powered coding assistant)"
            if install_claude; then
                log_success "Claude CLI installed successfully"
            else
                log_warn "Skipping Claude CLI - ensure Node.js is installed and try 'npm install -g @anthropic-ai/claude-cli' manually"
            fi
        fi

        # Install Claudevoyant plugin if Claude CLI is available
        if command_exists claude; then
            current=$((current + 1))
            progress_step $current "Checking Claudevoyant plugin"
            # Check if plugin is already installed
            if claude plugin list 2>/dev/null | grep -q "claudevoyant"; then
                log_success "Claudevoyant plugin is already installed"
            else
                log_info "Installing Claudevoyant plugin for slash commands"
                if install_claudevoyant_plugin; then
                    log_success "Claudevoyant plugin installed"
                else
                    log_warn "Skipping Claudevoyant plugin - you can install it later with 'claude plugin install claudevoyant'"
                fi
            fi
        fi
    fi

    # Check bats-core (for --ci or --template)
    if [ "$INSTALL_CI" = true ] || [ "$INSTALL_TEMPLATE" = true ]; then
        current=$((current + 1))
        progress_step $current "Checking bats-core"
        if command_exists bats; then
            log_success "bats-core is already installed: $(bats --version)"
        else
            log_warn "bats-core not found (needed for template testing)"
            if install_bats; then
                log_success "bats-core installed successfully"
            else
                log_warn "Skipping bats-core - install manually from https://github.com/bats-core/bats-core if needed"
            fi
        fi

        # Check GNU parallel (for --ci or --template)
        current=$((current + 1))
        progress_step $current "Checking GNU parallel"
        if command_exists parallel; then
            log_success "GNU parallel is already installed: $(parallel --version | head -n1)"
        else
            log_warn "GNU parallel not found (recommended for parallel test execution)"
            if install_parallel; then
                log_success "GNU parallel installed successfully"
            else
                log_warn "Skipping GNU parallel - tests will run sequentially"
            fi
        fi
    fi

    # Check starship (for --starship only)
    if [ "$INSTALL_STARSHIP" = true ]; then
        current=$((current + 1))
        progress_step $current "Checking starship"
        if command_exists starship; then
            log_success "starship is already installed: $(starship --version)"
        else
            log_warn "starship not found"
            if install_starship; then
                log_success "starship installed successfully"
                # Configure starship
                configure_starship
            else
                log_warn "Skipping starship - install manually from https://starship.rs if needed"
            fi
        fi
    fi

    # Allow direnv if installed and .envrc exists and is not already allowed
    if command_exists direnv && [ -f "$(dirname "$0")/../.envrc" ]; then
        if ! direnv status "$(dirname "$0")/.." 2>/dev/null | grep -q "Found RC allowed 0"; then
            log_info "Running direnv allow"
            direnv allow "$(dirname "$0")/.." >/dev/null 2>&1
            log_success "direnv allow completed"
        else
            log_success "direnv already allowed for this directory"
        fi
    fi

    # Cleanup if optimizing for Docker
    if [ "$DOCKER_OPTIMIZE" = true ]; then
        log_info "Cleaning up package caches"
        if [ "$PLATFORM" = "Linux" ]; then
            if command_exists apk; then
                sudo rm -rf /var/cache/apk/*
            elif command_exists apt-get; then
                sudo rm -rf /var/lib/apt/lists/*
            elif command_exists yum; then
                sudo yum clean all
            elif command_exists pacman; then
                sudo pacman -Sc --noconfirm
            fi
        fi
        if command_exists npm; then
            npm cache clean --force
        fi
        log_success "Cleanup completed"
    fi

    echo ""
    log_success "All required dependencies are installed!"
}

# MAIN -------------------------------------------------------------------------

detect_platform
check_dependencies

log_info "Setup complete! Run 'just build' to build, 'just test' to run tests, or 'just' to see all commands."
