# syntax=docker/dockerfile:1
# Dev container: full dev environment (mirrors Dockerfile dev stage)

FROM ubuntu:22.04 AS dev

USER root
COPY scripts /tmp/scripts
RUN cd /tmp/scripts && \
    chmod +x setup.sh && \
    ./setup.sh --dev --template --starship --docker-optimize && \
    rm -rf /tmp/scripts

RUN useradd -m -s /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN echo 'eval "$(direnv hook bash)"' >> /home/vscode/.bashrc && \
    echo 'eval "$(starship init bash)"' >> /home/vscode/.bashrc && \
    chown vscode:vscode /home/vscode/.bashrc

USER vscode
WORKDIR /workspaces

RUN mkdir -p ~/.config/direnv && \
    echo '[whitelist]' > ~/.config/direnv/direnv.toml && \
    echo 'prefix = [ "/workspaces" ]' >> ~/.config/direnv/direnv.toml
