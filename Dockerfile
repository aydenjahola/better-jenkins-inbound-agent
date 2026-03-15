FROM jenkins/inbound-agent:latest

USER root

ARG TARGETARCH
ARG NODE_VERSION=24.14.0
ARG GO_VERSION=1.26.1
ARG DOCKER_VERSION=29.3.0

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/go/bin:/opt/node/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    tar \
    xz-utils \
    gzip \
    unzip \
    bash \
    procps \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "${TARGETARCH:-amd64}" in \
      amd64) NODE_ARCH="x64"; GO_ARCH="amd64"; DOCKER_ARCH="x86_64" ;; \
      arm64) NODE_ARCH="arm64"; GO_ARCH="arm64"; DOCKER_ARCH="aarch64" ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz; \
    mkdir -p /opt/node; \
    tar -xJf /tmp/node.tar.xz -C /opt/node --strip-components=1; \
    rm -f /tmp/node.tar.xz; \
    ln -sf /opt/node/bin/node /usr/local/bin/node; \
    ln -sf /opt/node/bin/npm /usr/local/bin/npm; \
    ln -sf /opt/node/bin/npx /usr/local/bin/npx; \
    \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz; \
    rm -rf /usr/local/go; \
    tar -C /usr/local -xzf /tmp/go.tar.gz; \
    rm -f /tmp/go.tar.gz; \
    ln -sf /usr/local/go/bin/go /usr/local/bin/go; \
    ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt; \
    \
    curl -fsSL "https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz" -o /tmp/docker.tgz; \
    tar -xzf /tmp/docker.tgz -C /tmp; \
    install -m 0755 /tmp/docker/docker /usr/local/bin/docker; \
    rm -rf /tmp/docker /tmp/docker.tgz; \
    \
    node --version; \
    npm --version; \
    go version; \
    docker --version

RUN mkdir -p /home/jenkins/agent && chown -R jenkins:jenkins /home/jenkins /opt/node

WORKDIR /home/jenkins/agent
