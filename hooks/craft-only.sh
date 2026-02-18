#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  claude-plan-hook: Mode 3 — Craft Publish Only (No Approve)    ║
# ║                                                                  ║
# ║  PermissionRequest hook for ExitPlanMode.                       ║
# ║  Pushes the plan to Craft.do but does NOT auto-approve —       ║
# ║  the normal approval dialog still appears.                      ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Hook event:  PermissionRequest
# Matcher:     ExitPlanMode
# Requires:    CRAFT_API_URL and CRAFT_PAGE_ID written by the installer
#              into ~/.claude/hooks/craft-config.env

# ── Load Craft credentials ──────────────────────────────────────────
CRAFT_CONFIG="$HOME/.claude/hooks/craft-config.env"
if [ -f "$CRAFT_CONFIG" ]; then
  # shellcheck disable=SC1090
  source "$CRAFT_CONFIG"
fi

# ── Read hook payload into temp file ────────────────────────────────
TMPFILE=$(mktemp)
cat > "$TMPFILE"

# ── Push to Craft in background (non-blocking) ─────────────────────
if [ -n "$CRAFT_API_URL" ] && [ -n "$CRAFT_PAGE_ID" ]; then
  HAS_PLAN=$(jq -r '.tool_input.plan // empty' < "$TMPFILE" 2>/dev/null)

  if [ -n "$HAS_PLAN" ]; then
    (
      TIMESTAMP=$(date '+%H:%M - %d-%m-%Y')

      PAYLOAD=$(jq \
        --arg ts "$TIMESTAMP" \
        --arg pageId "$CRAFT_PAGE_ID" \
        '{
          blocks: [{
            type: "page",
            textStyle: "card",
            markdown: ("[\(.cwd)] - [" + $ts + "]"),
            content: [{
              type: "text",
              markdown: .tool_input.plan
            }]
          }],
          position: {
            position: "end",
            pageId: $pageId
          }
        }' < "$TMPFILE" 2>/dev/null)

      if [ -n "$PAYLOAD" ]; then
        curl -s -X POST "${CRAFT_API_URL}/blocks" \
          -H "Content-Type: application/json" \
          -d "$PAYLOAD" \
          > /dev/null 2>&1
      fi

      rm -f "$TMPFILE"
    ) &
  else
    rm -f "$TMPFILE"
  fi
else
  rm -f "$TMPFILE"
fi

# ── No approval decision — let the normal dialog appear ─────────────
exit 0
