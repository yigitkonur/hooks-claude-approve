# claude-plan-hook

Skip the "Ready to code?" prompt. Auto-approve Claude Code plans and optionally archive every plan to [Craft.do](https://craft.do).

```
                         PermissionRequest
                          (ExitPlanMode)
                               |
                     +---------+---------+
                     |                   |
               auto-approve         publish to
               (instant)            Craft.do
                     |              (background)
                     v                   |
              Claude continues           v
              implementing...     Plan archived as
                                  a Craft subpage
```

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yigitkonur/script-auto-approve-plan-cc/main/install.sh)
```

Or clone first:

```bash
git clone https://github.com/yigitkonur/script-auto-approve-plan-cc.git /tmp/claude-plan-hook \
  && bash /tmp/claude-plan-hook/install.sh \
  && rm -rf /tmp/claude-plan-hook
```

The installer is interactive and will prompt you to choose a mode.

## Modes

| Mode | Auto-approve | Craft.do | Use case |
|------|:---:|:---:|---|
| **1. Approve only** | Yes | No | Just skip the approval dialog |
| **2. Approve + Craft** | Yes | Yes | Skip approval and archive every plan |
| **3. Craft only** | No | Yes | Archive plans but still approve manually |

**Switching modes:** Run the installer again. It detects the existing install and cleanly swaps to the new mode.

## How it works

When Claude Code finishes writing a plan and calls `ExitPlanMode`, the UI shows a "Ready to code?" dialog with 4 options. This is a `PermissionRequest` hook event for the `ExitPlanMode` tool.

This hook intercepts that event and:

1. **Auto-approve** (modes 1, 2) — returns `{ behavior: "allow" }` so Claude proceeds immediately
2. **Publish to Craft** (modes 2, 3) — pushes the plan content to Craft.do as a subpage in the background, without blocking the approval

The hook uses the correct event (`PermissionRequest` with matcher `ExitPlanMode`), not the `Stop` event. This is important because the plan approval dialog fires _before_ Claude stops — it's waiting for user input.

### What gets pushed to Craft

Each plan becomes a subpage under your chosen Craft document:

- **Title:** `[/project/path] - [HH:MM - DD-MM-YYYY]`
- **Content:** The full plan markdown (headings, tables, lists are all preserved by Craft's parser)

## Craft.do setup

For modes 2 and 3, you need:

1. **Craft API URL** — Go to Craft Settings > API, create a new connection, and copy the endpoint URL. It looks like `https://connect.craft.do/links/YOUR_KEY/api/v1`.

2. **Parent page ID** — The UUID of the Craft page where plans will be nested as subpages. You can find this in the page's URL or via the Craft API.

The installer prompts for both and saves them to `~/.claude/hooks/craft-config.env` (permissions `600`). You can edit this file directly to update credentials.

## What the installer does

- Checks prerequisites (`jq`, and `curl` for Craft modes)
- Copies the hook script to `~/.claude/hooks/claude-plan-hook.sh`
- Uses `jq` to add a `PermissionRequest` hook with `ExitPlanMode` matcher to `~/.claude/settings.json`
- Removes old broken `Stop` hook entries from previous versions
- Saves Craft credentials to `~/.claude/hooks/craft-config.env` (modes 2, 3)
- Tests Craft API connectivity (modes 2, 3)

Re-running the installer with a different mode cleanly swaps the hook script and settings entry.

## Uninstall

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/yigitkonur/script-auto-approve-plan-cc/main/uninstall.sh)
```

Or manually:

```bash
rm ~/.claude/hooks/claude-plan-hook.sh
# Then remove the PermissionRequest ExitPlanMode entry from ~/.claude/settings.json
```

## Requirements

- macOS or Linux
- [jq](https://jqlang.github.io/jq/) — `brew install jq`
- `curl` (for Craft modes and remote install)
- Claude Code with hooks support

## Troubleshooting

**Plans aren't auto-approving:**
- Restart Claude Code after installing (settings are read at session start)
- Check that `~/.claude/settings.json` has a `PermissionRequest` entry with matcher `ExitPlanMode`
- Verify the hook script exists and is executable: `ls -la ~/.claude/hooks/claude-plan-hook.sh`

**Plans aren't appearing in Craft:**
- Check your credentials: `cat ~/.claude/hooks/craft-config.env`
- Test the API manually: `curl -s -X POST "YOUR_API_URL/blocks" -H "Content-Type: application/json" -d '{"blocks":[{"type":"text","markdown":"test"}],"position":{"position":"end","pageId":"YOUR_PAGE_ID"}}'`
- The Craft push runs in the background — if the main process exits too fast, the background curl may be killed. This is rare in normal usage.

**Upgrading from the old version (Stop hook):**
The installer automatically removes old `Stop` hook entries that reference `auto-approve`. No manual cleanup needed.

## License

MIT
