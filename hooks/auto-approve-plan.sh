#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  claude-plan-hook: Mode 1 — Auto-Approve Only                  ║
# ║                                                                  ║
# ║  PermissionRequest hook for ExitPlanMode.                       ║
# ║  Returns "allow" so Claude proceeds without the approval dialog.║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Hook event:  PermissionRequest
# Matcher:     ExitPlanMode
# Behavior:    Instantly approves plans — no user interaction needed.

# Consume stdin (required by hook protocol)
cat > /dev/null

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow",
      "message": "Plan auto-approved by claude-plan-hook"
    }
  }
}
EOF

exit 0
