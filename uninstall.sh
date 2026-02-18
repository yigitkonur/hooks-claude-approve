#!/bin/bash
set -euo pipefail

# ╔══════════════════════════════════════════════════════════════════╗
# ║  claude-plan-hook uninstaller                                   ║
# ╚══════════════════════════════════════════════════════════════════╝

HOOK_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
HOOK_SCRIPT="$HOOK_DIR/claude-plan-hook.sh"
CRAFT_CONFIG="$HOOK_DIR/craft-config.env"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

ok()   { printf "${GREEN}[ok]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[!!]${NC} %s\n" "$1"; }
info() { printf "${DIM}[..]${NC} %s\n" "$1"; }

printf "\n${BOLD}  claude-plan-hook uninstaller${NC}\n\n"

# ── Remove hook script ───────────────────────────────────────────────
if [ -f "$HOOK_SCRIPT" ]; then
  rm -f "$HOOK_SCRIPT"
  ok "Removed ${HOOK_SCRIPT}"
else
  info "Hook script not found (already removed)"
fi

# ── Remove Craft config ─────────────────────────────────────────────
if [ -f "$CRAFT_CONFIG" ]; then
  printf "${YELLOW}>${NC} Remove Craft credentials too? [y/N]: "
  read -r REMOVE_CRAFT
  if [ "$REMOVE_CRAFT" = "y" ] || [ "$REMOVE_CRAFT" = "Y" ]; then
    rm -f "$CRAFT_CONFIG"
    ok "Removed ${CRAFT_CONFIG}"
  else
    info "Kept ${CRAFT_CONFIG}"
  fi
fi

# ── Remove hook from settings.json ───────────────────────────────────
if [ -f "$SETTINGS" ] && command -v jq &>/dev/null; then
  # Check if PermissionRequest ExitPlanMode entry exists
  if jq -e '.hooks.PermissionRequest[]? | select(.matcher == "ExitPlanMode")' "$SETTINGS" &>/dev/null; then
    TMP=$(mktemp)
    jq '
      # Remove ExitPlanMode matcher entries
      .hooks.PermissionRequest = [
        .hooks.PermissionRequest[]? |
        select(.matcher != "ExitPlanMode")
      ] |

      # Clean up empty PermissionRequest array
      if .hooks.PermissionRequest == [] then del(.hooks.PermissionRequest) else . end |

      # Also remove any old Stop hook auto-approve entries
      if .hooks.Stop then
        .hooks.Stop = [
          .hooks.Stop[]? |
          .hooks = [.hooks[]? | select(.command | test("auto-approve|claude-plan-hook"; "i") | not)]
        ] |
        .hooks.Stop = [.hooks.Stop[]? | select(.hooks | length > 0)]
      else . end |
      if .hooks.Stop == [] then del(.hooks.Stop) else . end |

      # Remove empty hooks object
      if .hooks == {} then del(.hooks) else . end
    ' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
    ok "Removed hook entry from ${SETTINGS}"
  else
    info "No hook entry found in settings.json"
  fi
else
  if [ ! -f "$SETTINGS" ]; then
    info "No settings.json found"
  else
    warn "jq not found — cannot clean settings.json automatically"
    printf "  ${DIM}Manually remove the ExitPlanMode entry from ${SETTINGS}${NC}\n"
  fi
fi

printf "\n${GREEN}${BOLD}Uninstalled.${NC}\n"
printf "  ${DIM}Restart Claude Code for changes to take effect.${NC}\n\n"
