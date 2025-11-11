#!/usr/bin/env bash
set -euo pipefail

command -v iptables >/dev/null 2>&1 || { echo "iptables not found; skipping firewall."; exit 0; }
if ! iptables -L OUTPUT >/dev/null 2>&1; then
  echo "No permission to manage iptables. Did you set --cap-add=NET_ADMIN? Skipping."
  exit 0
fi

DEFAULT_ALLOW_DOMAINS=(
  "registry.npmjs.org"
  "npmjs.org"
  "github.com"
  "api.github.com"
  "objects.githubusercontent.com"
  "claude.ai"
  "api.anthropic.com"
  "console.anthropic.com"
)
EXTRA="${EXTRA_ALLOW_DOMAINS:-}"
ALLOW_DOMAINS=("${DEFAULT_ALLOW_DOMAINS[@]}")
if [[ -n "$EXTRA" ]]; then
  for d in $EXTRA; do ALLOW_DOMAINS+=("$d"); done
fi

echo "Applying egress firewall (default deny), whitelisting: ${ALLOW_DOMAINS[*]}"

iptables -P OUTPUT ACCEPT
iptables -F OUTPUT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

for ns in $(awk '/^nameserver/{print $2}' /etc/resolv.conf | tr -d '[]'); do
  iptables -A OUTPUT -p udp -d "$ns" --dport 53 -j ACCEPT || true
  iptables -A OUTPUT -p tcp -d "$ns" --dport 53 -j ACCEPT || true
done

resolve_ips() { local host="$1"; getent ahostsv4 "$host" | awk '{print $1}' | sort -u; }

for host in "${ALLOW_DOMAINS[@]}"; do
  for ip in $(resolve_ips "$host"); do
    iptables -A OUTPUT -p tcp -d "$ip" --dport 443 -j ACCEPT || true
  done
done

if [[ "${ALLOW_SSH_ANY:-0}" = "1" ]]; then
  iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
else
  for ip in $(resolve_ips "github.com"); do
    iptables -A OUTPUT -p tcp -d "$ip" --dport 22 -j ACCEPT || true
  done
fi

allow_proxy_from_env() {
  # Extract proxy from HTTP(S)_PROXY or ALL_PROXY environment variables
  PROXY_RAW="${HTTP_PROXY:-${HTTPS_PROXY:-${ALL_PROXY:-}}}"
  [ -z "$PROXY_RAW" ] && return 0

  # Remove protocol prefix and extract host:port
  PROXY_HP="${PROXY_RAW#*://}"
  PROXY_HP="${PROXY_HP%%/*}"
  PROXY_HOST="${PROXY_HP%:*}"
  PROXY_PORT="${PROXY_HP#*:}"

  # Validate we have both host and port
  [ -z "$PROXY_HOST" ] || [ -z "$PROXY_PORT" ] && return 0
  [ "$PROXY_HOST" = "$PROXY_PORT" ] && return 0  # No port specified

  echo "Allowlisting proxy: $PROXY_HOST:$PROXY_PORT"

  # Resolve proxy host to IPv4 addresses and allow TCP connections to the proxy port
  for ip in $(getent ahostsv4 "$PROXY_HOST" 2>/dev/null | awk '{print $1}' | sort -u); do
    iptables -A OUTPUT -p tcp -d "$ip" --dport "$PROXY_PORT" -j ACCEPT || true
  done
}

# Allow proxy connections before setting default DROP policy
allow_proxy_from_env

iptables -P OUTPUT DROP
iptables -S OUTPUT || true
