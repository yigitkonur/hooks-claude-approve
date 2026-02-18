# Auto-Approve Plan Hook for Claude Code

A Stop hook that automatically approves plans in Claude Code's plan mode — without blocking research or exploration phases.

## Problem

Claude Code's plan mode requires manual approval when `ExitPlanMode` is called. A naive Stop hook that blocks in plan mode causes Claude to loop endlessly during research/exploration, because it blocks **every** stop — not just plan submissions.

## Solution

This hook checks the session transcript to confirm `ExitPlanMode` was actually called before auto-approving. Research stops pass through cleanly.

## One-liner install

```bash
git clone https://github.com/yigitkonur/script-auto-approve-plan-cc.git /tmp/auto-approve-plan-cc && bash /tmp/auto-approve-plan-cc/install.sh && rm -rf /tmp/auto-approve-plan-cc
```

## Manual install

```bash
# 1. Copy the hook
mkdir -p ~/.claude/hooks
cp auto-approve-plan.sh ~/.claude/hooks/auto-approve-plan.sh
chmod +x ~/.claude/hooks/auto-approve-plan.sh

# 2. Run the installer to wire up settings.json
bash install.sh
```

## How it works

The hook receives JSON on stdin from Claude Code's Stop event. It:

1. **Exits early** if not in plan mode — zero overhead in normal usage
2. **Reads `transcript_path`** from the hook input
3. **Checks the last 10KB** of the transcript JSONL for an `ExitPlanMode` tool call
4. **Only then** returns `{"decision": "block"}` to auto-approve the plan

If Claude stopped for any other reason (research, exploration, thinking), the hook exits silently and Claude proceeds normally.

## What the installer does

- Creates `~/.claude/hooks/` if it doesn't exist
- Copies `auto-approve-plan.sh` and makes it executable
- Uses `jq` to merge the Stop hook config into `~/.claude/settings.json`
- **Re-install safe**: skips the settings merge if the hook is already configured

## Requirements

- [jq](https://jqlang.github.io/jq/) — `brew install jq` / `apt install jq`
- Claude Code with hooks support

## Uninstall

```bash
rm ~/.claude/hooks/auto-approve-plan.sh
```

Then remove the Stop hook entry from `~/.claude/settings.json` (or leave it — it's harmless without the script file).

## License

MIT
