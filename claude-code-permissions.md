# Claude Code: Maximum Permissions with Guardrails

A setup that gives Claude Code full autonomous permissions while preventing catastrophic mistakes. Works with any launch method including `ollama launch claude`.

## The Problem

Claude Code has three permission levels by default and prompts you constantly. The `--dangerously-skip-permissions` flag removes all prompts but only works as a CLI flag — you can't pass it when launching via `ollama launch claude` or other integrations.

## The Solution

Two layers of protection configured in `~/.claude/settings.json`:

1. **Permissions config** -- grants full tool access with basic deny rules (prefix matching)
2. **PreToolUse hook** -- a bash script that inspects every command with regex before execution

### Layer 1: Settings (~/.claude/settings.json)

```json
{
  "permissions": {
    "defaultMode": "bypassPermissions",
    "allow": [
      "Bash",
      "Read",
      "Write",
      "Edit",
      "NotebookEdit",
      "Update"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(rm -rf /*)",
      "Bash(rm -rf ~)",
      "Bash(rm -rf ~/*)",
      "Bash(npm publish*)",
      "Bash(pnpm publish*)",
      "Bash(npx publish*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/guardrails.sh",
            "timeout": 5,
            "statusMessage": "Checking guardrails..."
          }
        ]
      }
    ]
  }
}
```

**Key settings explained:**

| Setting | Purpose |
|---|---|
| `defaultMode: "bypassPermissions"` | Starts every session in bypass mode -- no CLI flag needed. Works with `ollama launch claude`, `clauded`, or plain `claude`. |
| `allow: ["Bash", ...]` | Tool names without parentheses = allow ALL uses of that tool. |
| `deny: [...]` | Prefix-matched deny rules. Catches exact patterns like `rm -rf /`. Limited because flag order can vary. |
| `hooks.PreToolUse` | Runs `guardrails.sh` before every Bash command for regex-based inspection. |

### Layer 2: Hook Script (~/.claude/hooks/guardrails.sh)

The deny rules in settings.json use prefix matching which can't catch things like `git push origin main --force` (flag at the end). The hook script uses regex and can inspect the full command string.

**What it blocks:**

| Command | Why |
|---|---|
| `git push --force` / `-f` | Blocks force push. Suggests `--force-with-lease` instead. |
| `git reset --hard` on main/staging | Blocks hard reset on shared branches only. Allowed on feature branches. |
| `git clean -f` | Permanently deletes untracked files. |
| `rm -rf` on system paths | Blocks recursive delete on `/`, `~`, `/Users`, etc. Allows safe targets like `node_modules`, `dist`, `.next`. |
| `docker system prune` | Removes all unused containers, images, volumes. |
| `chmod -R 777` | Makes everything world-writable. |
| `npm/pnpm/yarn publish` | Prevents accidental package publishing. |
| `DROP DATABASE` / `TRUNCATE` | Blocks destructive SQL commands. |
| `curl -X DELETE/PUT` to prod URLs | Blocks destructive HTTP methods against production. |

**Exit codes:**
- `0` = command allowed (pass through)
- `2` = command blocked (reason shown to user)

## Setup Instructions

### 1. Create the hooks directory

```bash
mkdir -p ~/.claude/hooks
```

### 2. Create the hook script

Copy the `guardrails.sh` file to `~/.claude/hooks/guardrails.sh` and make it executable:

```bash
chmod +x ~/.claude/hooks/guardrails.sh
```

### 3. Update settings.json

Edit `~/.claude/settings.json` and add the `permissions`, `hooks` sections as shown above. Merge with any existing settings (model, plugins, etc.).

### 4. Verify

Start a new Claude Code session (any method) and try:

```
> run: git push --force origin main
```

You should see the guardrail block message instead of execution.

## Customising

### Adding new guardrails

Edit `~/.claude/hooks/guardrails.sh`. The pattern is:

```bash
if echo "$CMD" | grep -qE 'your-regex-pattern'; then
  echo '{"decision":"block","reason":"GUARDRAIL: Your reason here."}' >&2
  exit 2
fi
```

### Allowing safe patterns through rm -rf

The script has an allowlist for common cleanup targets. Add more:

```bash
if echo "$CMD" | grep -qE 'rm\s+-rf\s+(node_modules|dist|\.next|YOUR_DIR)'; then
  exit 0
fi
```

### Adding deny rules to settings.json

Deny rules use **prefix matching** only. Good for exact command starts:

```json
"deny": ["Bash(dangerous-command*)"]
```

For anything requiring flag inspection or complex patterns, use the hook script instead.

## Valid defaultMode Values

| Mode | Behaviour |
|---|---|
| `default` | Standard three-level prompting |
| `plan` | Read-only analysis, no file changes |
| `acceptEdits` | Auto-accepts file edits, prompts for bash |
| `bypassPermissions` | Skips all permission prompts (equivalent to `--dangerously-skip-permissions`) |
| `dontAsk` | Never prompts, denies anything not explicitly allowed |
| `delegate` | Delegates permission decisions |

## File Locations

```
~/.claude/
  settings.json          # Global Claude Code settings
  hooks/
    guardrails.sh        # PreToolUse guardrail script
    GUARDRAILS-GUIDE.md  # This guide
```
