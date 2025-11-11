#!/usr/bin/env bash
set -euo pipefail

npm i -g @anthropic-ai/claude-code

# Ensure $HOME/.claude (mounted volume) is writable by current user
CLAUDE_HOME="$HOME/.claude"
if ! mkdir -p "$CLAUDE_HOME" 2>/dev/null; then
  sudo mkdir -p "$CLAUDE_HOME"
fi
if ! touch "$CLAUDE_HOME/.permcheck" 2>/dev/null; then
  sudo chown -R "$(id -u)":"$(id -g)" "$CLAUDE_HOME" || true
fi
rm -f "$CLAUDE_HOME/.permcheck" 2>/dev/null || true

mkdir -p "$CLAUDE_HOME/bin" "$CLAUDE_HOME/commands" "$CLAUDE_HOME/skills"
CFG="$CLAUDE_HOME/settings.json"

LOGIN_METHOD="${CLAUDE_LOGIN_METHOD:-claudeai}"

# ---- Base policy (BYPASS BY DEFAULT) & marketplace/plugins ----
read -r -d '' BASE_CFG <<'JSON'
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(**/id_rsa)",
      "Read(**/id_ed25519)"
    ],
    "defaultMode": "bypassPermissions"
  },
  "extraKnownMarketplaces": {
    "claude-code-plugins": {
      "source": { "source": "github", "repo": "anthropics/claude-code" }
    }
  },
  "enabledPlugins": {
    "commit-commands@claude-code-plugins": true,
    "pr-review-toolkit@claude-code-plugins": true,
    "security-guidance@claude-code-plugins": true
  }
}
JSON

# ---- Login method preset ----
if [[ -n "${CLAUDE_ORG_UUID:-}" ]]; then
  LOGIN_CFG=$(jq -n \
    --arg m "$LOGIN_METHOD" \
    --arg org "$CLAUDE_ORG_UUID" \
    '{forceLoginMethod:$m, forceLoginOrgUUID:$org}')
else
  LOGIN_CFG=$(jq -n --arg m "$LOGIN_METHOD" '{forceLoginMethod:$m}')
fi

# ---- API key helper (non-interactive) ----
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  cat > "$HOME/.claude/bin/apikey.sh" <<'SH'
#!/usr/bin/env sh
[ -n "$ANTHROPIC_API_KEY" ] && { printf "%s" "$ANTHROPIC_API_KEY"; exit 0; }
echo "ANTHROPIC_API_KEY not set" >&2; exit 1
SH
  chmod 700 "$HOME/.claude/bin/apikey.sh"
  API_HELPER_CFG=$(jq -n --arg path "$HOME/.claude/bin/apikey.sh" '{apiKeyHelper:$path}')
else
  API_HELPER_CFG='{}'
fi

# ---- Optional: sandbox ----
if [[ "${ENABLE_CLAUDE_SANDBOX:-}" = "1" ]]; then
  SANDBOX_CFG=$(jq -n \
    '{sandbox: {allowUnsandboxedCommands: false, enableWeakerNestedSandbox: true}}')
else
  SANDBOX_CFG='{}'
fi

# ---- Merge settings (existing -> base -> login -> apiHelper -> sandbox) ----
if [[ -f "$CFG" ]]; then
  tmp="$(mktemp)"
  jq -s '.[0] * .[1] * .[2] * .[3] * .[4]' \
    "$CFG" \
    <(printf '%s' "$BASE_CFG") \
    <(printf '%s' "$LOGIN_CFG") \
    <(printf '%s' "$API_HELPER_CFG") \
    <(printf '%s' "$SANDBOX_CFG") \
    > "$tmp" && mv "$tmp" "$CFG"
else
  tmp="$(mktemp)"
  jq -s '.[0] * .[1] * .[2] * .[3]' \
    <(printf '%s' "$BASE_CFG") \
    <(printf '%s' "$LOGIN_CFG") \
    <(printf '%s' "$API_HELPER_CFG") \
    <(printf '%s' "$SANDBOX_CFG") \
    > "$tmp" && mv "$tmp" "$CFG"
fi

# ---- Seeds ----
if [[ ! -f "$HOME/.claude/CLAUDE.md" ]]; then
  cat > "$HOME/.claude/CLAUDE.md" <<'MD'
# Global notes for Claude Code
- Mode: BYPASS by default (use with trusted repos only)
- Conventions: src/, tests/, docs/
- Safety: do not read `.env*` or `secrets/**` unless explicitly asked
- Tools: bash, gh, node, python
MD
fi

cat > "$HOME/.claude/commands/review-pr.md" <<'CMD'
Analyze a GitHub PR and suggest actionable review points for $ARGUMENTS.
Use `gh pr view $ARGUMENTS --comments` to gather context; produce a concise checklist + suggested diffs.
CMD

mkdir -p "$HOME/.claude/skills/reviewing-prs"
cat > "$HOME/.claude/skills/reviewing-prs/SKILL.md" <<'SK'
---
name: reviewing-prs
description: Provide concise review checklists and PR summaries.
---
Focus on correctness, security, performance, readability.
SK

# ---- TTL passthrough ----
if [[ -n "${CLAUDE_CODE_API_KEY_HELPER_TTL_MS:-}" ]]; then
  tmp="$(mktemp)"
  jq '.env = (.env // {})
      + {"CLAUDE_CODE_API_KEY_HELPER_TTL_MS": env.CLAUDE_CODE_API_KEY_HELPER_TTL_MS}' \
    "$CFG" > "$tmp" && mv "$tmp" "$CFG"
fi

echo "✔ Claude Code installed. BYPASS mode is the default."
[[ -n "${CLAUDE_ORG_UUID:-}" ]] && echo "   forceLoginOrgUUID=$CLAUDE_ORG_UUID"
[[ -n "${ANTHROPIC_API_KEY:-}" ]] && echo "   apiKeyHelper enabled"
