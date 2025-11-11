#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then echo "Usage: $0 <path|git-url>"; exit 1; fi

# Resolve project directory
if [[ "$1" =~ ^https?://|git@ ]]; then
  TMP="${HOME}/.cache/universal-dev/$(date +%s)"; mkdir -p "$(dirname "$TMP")"
  git clone --depth=1 "$1" "$TMP"
  PROJECT_DIR="$TMP"
else
  PROJECT_DIR="$(cd "$1" && pwd)"
fi
export PROJECT_DIR
PROJECT_NAME="$(basename "$PROJECT_DIR")"
export PROJECT_NAME

# Repo root (this universal devcontainer)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Write local override to bind the chosen project directory
LOCAL_JSON="$REPO_ROOT/.devcontainer/devcontainer.local.json"
mkdir -p "$REPO_ROOT/.devcontainer"

json_escape() {
  # minimal JSON escape for backslash and quotes
  printf '%s' "$1" | sed -e 's/\\\\/\\\\\\\\/g' -e 's/\"/\\\"/g'
}

PD_ESC="$(json_escape "$PROJECT_DIR")"
PN_ESC="$(json_escape "$PROJECT_NAME")"

cat > "$LOCAL_JSON" <<EOF
{
  "workspaceMount": "source=$PD_ESC,target=/workspaces/$PN_ESC,type=bind,consistency=cached",
  "workspaceFolder": "/workspaces/$PN_ESC"
}
EOF

echo "[universal-devcontainer] Wrote override: $LOCAL_JSON"
echo "Opening devcontainer at $REPO_ROOT with project: $PROJECT_DIR"
code "$REPO_ROOT"
