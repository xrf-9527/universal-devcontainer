FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Accept proxy settings as build arguments
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG NO_PROXY

# Set proxy environment variables for build time
ENV http_proxy=${HTTP_PROXY}
ENV https_proxy=${HTTPS_PROXY}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV NO_PROXY=${NO_PROXY}
ENV no_proxy=${NO_PROXY}

# Configure APT to use proxy if provided
RUN if [ -n "${HTTP_PROXY}" ]; then \
      echo "Acquire::http::Proxy \"${HTTP_PROXY}\";" > /etc/apt/apt.conf.d/99proxy && \
      echo "Acquire::https::Proxy \"${HTTPS_PROXY}\";" >> /etc/apt/apt.conf.d/99proxy; \
    fi

RUN apt-get update && \
    apt-get install -y \
      git \
      curl \
      jq \
      iptables \
      dnsutils \
      sudo \
      ca-certificates \
      unzip \
      netcat-traditional && \
    rm -rf /var/lib/apt/lists/*

# Ensure workspace directory always exists even if external mount is absent
RUN mkdir -p /workspace && chown -R vscode:vscode /workspace

# Add first-open MOTD-style banner to show PROJECT_PATH and mount status
RUN tee /usr/local/bin/devcontainer-banner.sh >/dev/null <<'SH' \
 && chmod +x /usr/local/bin/devcontainer-banner.sh \
 && printf '\n# devcontainer banner (interactive shells)\nif [ -n "$PS1" ]; then /usr/local/bin/devcontainer-banner.sh 2>/dev/null || true; fi\n' >> /etc/bash.bashrc
#!/usr/bin/env bash
set -euo pipefail

# Only for interactive shells
if [ -z "${PS1:-}" ]; then exit 0; fi

FLAG="/tmp/.devcontainer_banner_shown"
if [ -f "$FLAG" ]; then exit 0; fi
touch "$FLAG" || true

PROJECT="${PROJECT_PATH:-}"
WS="/workspace"
UNI="/universal"

is_mounted() {
  grep -qE " $1 " /proc/mounts 2>/dev/null
}

status_ws="absent"
if [ -d "$WS" ]; then
  if is_mounted "$WS"; then status_ws="mounted"; else status_ws="dir-only"; fi
fi

status_uni="missing"
if is_mounted "$UNI"; then status_uni="mounted"; else status_uni="missing"; fi

cat <<EOT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Dev Container — Workspace status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 PROJECT_PATH: ${PROJECT:-<not set>}
 /workspace:   ${status_ws}
 /universal:   ${status_uni}
 Tip: set PROJECT_PATH via scripts/open-project.sh or dev.containers.defaultEnv
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOT
SH
