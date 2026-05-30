# syntax=docker/dockerfile:1
# Base image: mise installs all tools, then installs project dependencies

FROM ubuntu:22.04

# Install mise prerequisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl git sudo && \
    rm -rf /var/lib/apt/lists/*

# Install mise into a stable location
ENV MISE_DATA_DIR=/usr/local/mise
ENV MISE_CONFIG_DIR=/usr/local/mise-config
ENV PATH="/usr/local/mise/shims:/usr/local/mise/bin:${PATH}"
RUN curl -fsSL https://mise.run | sh && mise --version

WORKDIR /app
COPY . .

# Install all tools declared in mise.toml [tools] (node, pnpm, terraform, etc.)
RUN mise trust --yes && mise install

# Install project dependencies
RUN mise run install

LABEL org.opencontainers.image.title="${PROJECT} Base Image"
