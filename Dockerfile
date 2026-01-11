# ==============================================================================
# Base stage: Minimal runtime for docker-compose (run/test)
# ==============================================================================
FROM ubuntu:22.04 AS base

# Install minimal base dependencies
# NOTE: Package list cleanup happens after setup.sh (which may add more packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    sudo \
    git \
    ca-certificates

# Create non-root user
RUN useradd -m -s /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy setup scripts
COPY scripts /tmp/scripts

# Install required dependencies only (bash, just, direnv)
RUN cd /tmp/scripts && \
    chmod +x setup.sh && \
    ./setup.sh --docker-optimize && \
    rm -rf /tmp/scripts

USER vscode
WORKDIR /workspaces

# Configure direnv to auto-allow .envrc files (dev container convenience)
RUN mkdir -p ~/.config/direnv && \
    echo '[whitelist]' > ~/.config/direnv/direnv.toml && \
    echo 'prefix = [ "/workspaces" ]' >> ~/.config/direnv/direnv.toml

# ==============================================================================
# Dev stage: Full development environment for DevContainers
# ==============================================================================
FROM base AS dev

USER root

# Copy setup scripts again for dev tools installation
COPY scripts /tmp/scripts

# Install development tools (docker, node/npx, gcloud, shellcheck, shfmt, claude)
# and template testing tools (bats-core) and starship prompt
RUN cd /tmp/scripts && \
    chmod +x setup.sh && \
    ./setup.sh --dev --template --starship --docker-optimize && \
    rm -rf /tmp/scripts

# Add direnv hook to vscode user's bashrc
RUN echo 'eval "$(direnv hook bash)"' >> /home/vscode/.bashrc && \
    chown vscode:vscode /home/vscode/.bashrc

# Add starship prompt initialization to bashrc
RUN echo 'eval "$(starship init bash)"' >> /home/vscode/.bashrc && \
    chown vscode:vscode /home/vscode/.bashrc

USER vscode
WORKDIR /workspaces

# # ==============================================================================
# # Service
# # ==============================================================================

# FROM base AS service

# # TODO: make minimal as needed
# COPY . .
# RUN just build

# USER node
# ENV PORT=8080
# EXPOSE 8080

# # TODO: modify entrypoint as needed
# CMD ["just", "run"]

