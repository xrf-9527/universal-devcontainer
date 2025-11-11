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
