#!/usr/bin/env bash
#
# setup-proxy.sh
# Configure package managers and tools to use the host proxy
# Usage: bash .devcontainer/setup-proxy.sh
#

set -euo pipefail

echo "=== Configuring proxy for package managers and tools ==="

# Check if proxy environment variables are set
if [[ -z "${HTTP_PROXY:-}" ]] && [[ -z "${HTTPS_PROXY:-}" ]] && [[ -z "${ALL_PROXY:-}" ]]; then
  echo "No proxy environment variables found (HTTP_PROXY, HTTPS_PROXY, ALL_PROXY)."
  echo "Skipping proxy configuration."
  exit 0
fi

# Use HTTP_PROXY if set, otherwise fall back to HTTPS_PROXY
PROXY_HTTP="${HTTP_PROXY:-${HTTPS_PROXY:-}}"
PROXY_HTTPS="${HTTPS_PROXY:-${HTTP_PROXY:-}}"
PROXY_ALL="${ALL_PROXY:-}"

echo "Detected proxy configuration:"
[[ -n "$PROXY_HTTP" ]] && echo "  HTTP_PROXY:  $PROXY_HTTP"
[[ -n "$PROXY_HTTPS" ]] && echo "  HTTPS_PROXY: $PROXY_HTTPS"
[[ -n "$PROXY_ALL" ]] && echo "  ALL_PROXY:   $PROXY_ALL"

# Configure APT (Debian/Ubuntu)
if command -v apt-get >/dev/null 2>&1; then
  echo ""
  echo "Configuring APT proxy..."
  if [[ -n "$PROXY_HTTP" ]]; then
    sudo tee /etc/apt/apt.conf.d/99proxy >/dev/null <<EOF
Acquire::http::Proxy  "$PROXY_HTTP";
Acquire::https::Proxy "$PROXY_HTTPS";
EOF
    echo "  ✓ APT proxy configured in /etc/apt/apt.conf.d/99proxy"
  fi
fi

# Configure npm
if command -v npm >/dev/null 2>&1; then
  echo ""
  echo "Configuring npm proxy..."
  if [[ -n "$PROXY_HTTP" ]]; then
    npm config set proxy "$PROXY_HTTP"
    npm config set https-proxy "$PROXY_HTTPS"
    echo "  ✓ npm proxy configured"
  fi
fi

# Configure pip
if command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
  echo ""
  echo "Configuring pip proxy..."
  if [[ -n "$PROXY_HTTP" ]]; then
    mkdir -p ~/.config/pip
    cat > ~/.config/pip/pip.conf <<EOF
[global]
proxy = $PROXY_HTTP
EOF
    echo "  ✓ pip proxy configured in ~/.config/pip/pip.conf"
  fi
fi

# Configure git
if command -v git >/dev/null 2>&1; then
  echo ""
  echo "Configuring git proxy..."
  if [[ -n "$PROXY_HTTP" ]]; then
    git config --global http.proxy "$PROXY_HTTP"
    git config --global https.proxy "$PROXY_HTTPS"
    echo "  ✓ git proxy configured globally"
  fi
fi

# Configure yarn (if installed)
if command -v yarn >/dev/null 2>&1; then
  echo ""
  echo "Configuring yarn proxy..."
  if [[ -n "$PROXY_HTTP" ]]; then
    yarn config set proxy "$PROXY_HTTP"
    yarn config set https-proxy "$PROXY_HTTPS"
    echo "  ✓ yarn proxy configured"
  fi
fi

# Configure wget
if command -v wget >/dev/null 2>&1; then
  echo ""
  echo "Configuring wget proxy..."
  if [[ -n "$PROXY_HTTP" ]]; then
    : > ~/.wgetrc
    cat > ~/.wgetrc <<EOF
http_proxy = $PROXY_HTTP
https_proxy = $PROXY_HTTPS
use_proxy = on
EOF
    echo "  ✓ wget proxy configured in ~/.wgetrc"
  fi
fi

echo ""
echo "=== Proxy configuration complete ==="
echo ""
echo "Tip: To verify proxy is working, try:"
echo "  curl -I https://www.google.com"
echo "  nc -vz host.docker.internal 7890  # Test direct connection to proxy"
