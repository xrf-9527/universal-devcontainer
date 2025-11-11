#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
export PROJECT_DIR PROJECT_NAME

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Write local override to bind the current directory
LOCAL_JSON="$REPO_ROOT/.devcontainer/devcontainer.local.json"
mkdir -p "$REPO_ROOT/.devcontainer"

json_escape() {
  printf '%s' "$1" | sed -e 's/\\\\/\\\\\\\\/g' -e 's/\"/\\\"/g'
}

PD_ESC="$(json_escape "$PROJECT_DIR")"
PN_ESC="$(json_escape "$PROJECT_NAME")"

cat > "$LOCAL_JSON" <<EOF
{
  "mounts": [
    "source=$PD_ESC,target=/workspaces/$PN_ESC,type=bind,consistency=cached"
  ],
  "workspaceFolder": "/workspaces/$PN_ESC"
}
EOF

echo "[universal-devcontainer] Wrote override: $LOCAL_JSON"
echo "Opening devcontainer at $REPO_ROOT with project: $PROJECT_DIR"
code "$REPO_ROOT"
