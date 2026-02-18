#!/bin/bash
set -euo pipefail

HOOK_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SCRIPT="$HOOK_DIR/auto-approve-plan.sh"

echo "=== Auto-Approve Plan Hook for Claude Code ==="
echo ""

# ── Prerequisites ──────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required but not installed."
  echo "  brew install jq   # macOS"
  echo "  sudo apt install jq   # Ubuntu/Debian"
  exit 1
fi

# ── Install hook script ───────────────────────────────────────
mkdir -p "$HOOK_DIR"
cp -f "$SCRIPT_DIR/auto-approve-plan.sh" "$HOOK_SCRIPT"
chmod +x "$HOOK_SCRIPT"
echo "[ok] Hook script installed to $HOOK_SCRIPT"

# ── Merge hook config into settings.json ──────────────────────
# The desired Stop hook entry
HOOK_CMD="~/.claude/hooks/auto-approve-plan.sh"

if [ ! -f "$SETTINGS" ]; then
  # No settings file yet — create one with just the hook
  cat > "$SETTINGS" <<'ENDJSON'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/auto-approve-plan.sh"
          }
        ]
      }
    ]
  }
}
ENDJSON
  echo "[ok] Created $SETTINGS with Stop hook"
else
  # Settings file exists — check if hook is already present
  if jq -e '.hooks.Stop[]?.hooks[]? | select(.command == "~/.claude/hooks/auto-approve-plan.sh")' "$SETTINGS" &>/dev/null; then
    echo "[ok] Stop hook already present in $SETTINGS (no change)"
  else
    # Add the Stop hook entry, preserving everything else
    TMP=$(mktemp)
    jq '
      .hooks //= {} |
      .hooks.Stop //= [] |
      .hooks.Stop += [{"hooks": [{"type": "command", "command": "~/.claude/hooks/auto-approve-plan.sh"}]}]
    ' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
    echo "[ok] Stop hook added to $SETTINGS"
  fi
fi

echo ""
echo "Done! Usage:"
echo "  1. Open Claude Code"
echo "  2. Enter plan mode (Shift+Tab)"
echo "  3. Give it a task — when it calls ExitPlanMode, the plan auto-approves"
echo "  4. Research/exploration stops are NOT blocked"
