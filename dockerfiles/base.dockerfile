# syntax=docker/dockerfile:1
# Base image: full build environment with source and dependencies

FROM ubuntu:22.04

WORKDIR /app

# Copy everything (respecting .dockerignore)
COPY . .

# Force HTTPS for apt to work around ISP-level HTTP blocking (discovered in production).
# Installs ca-certificates first so subsequent apt calls can verify TLS.
RUN sed -i 's|http://|https://|g' /etc/apt/sources.list && \
  echo 'Acquire::https::Verify-Peer "false";' > /etc/apt/apt.conf.d/99verify-peer.conf && \
  apt-get update && \
  apt-get install -y ca-certificates && \
  rm /etc/apt/apt.conf.d/99verify-peer.conf && \
  apt-get update && \
  apt-get install -y sudo curl gnupg && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  bash scripts/setup.sh --docker-optimize --ci

# Ensure pnpm is available globally
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Verify Node.js is available, then install project dependencies
RUN node --version && npm --version && just install

LABEL org.opencontainers.image.title="${PROJECT} Base Image"
