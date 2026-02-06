#!/usr/bin/env bash
# Claude Code Guardrails Hook
# Blocks catastrophic bash commands while allowing maximum flexibility.
# Exit codes: 0 = allow, 2 = block (shows reason to user)

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only inspect Bash commands
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# --- Force push protection ---
# Match -f or --force only as standalone flags (not inside branch names like "vuln-fixes")
# \s-f(\s|$) ensures -f is a flag, not part of a word; --force(\s|$) excludes --force-with-lease
if echo "$CMD" | grep -qE 'git\s+push\b.*\s-f(\s|$)' || echo "$CMD" | grep -qE 'git\s+push\b.*\s--force(\s|$)'; then
  echo '{"decision":"block","reason":"GUARDRAIL: git push --force is blocked. Use --force-with-lease instead, or ask the user to confirm."}' >&2
  exit 2
fi

# --- Hard reset protection on shared branches ---
if echo "$CMD" | grep -qE 'git\s+reset\s+--hard'; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "")
  if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ] || [ "$BRANCH" = "staging" ]; then
    echo '{"decision":"block","reason":"GUARDRAIL: git reset --hard is blocked on '"$BRANCH"'. Switch to a feature branch first."}' >&2
    exit 2
  fi
fi

# --- git clean with force ---
if echo "$CMD" | grep -qE 'git\s+clean\s+.*-[a-zA-Z]*f'; then
  echo '{"decision":"block","reason":"GUARDRAIL: git clean -f is blocked. This permanently deletes untracked files."}' >&2
  exit 2
fi

# --- Recursive rm outside project directory ---
if echo "$CMD" | grep -qE 'rm\s+.*-[a-zA-Z]*r[a-zA-Z]*f|rm\s+.*-[a-zA-Z]*f[a-zA-Z]*r'; then
  # Allow rm -rf within known safe patterns (node_modules, dist, .next, etc.)
  if echo "$CMD" | grep -qE 'rm\s+-rf\s+(node_modules|dist|\.next|\.turbo|build|coverage|\.cache|tmp|__pycache__)'; then
    exit 0
  fi
  # Block rm -rf on home dir, root, or absolute paths outside project
  if echo "$CMD" | grep -qE 'rm\s+-rf\s+(/|~|/Users|/home|/etc|/var|/usr|\$HOME)'; then
    echo '{"decision":"block","reason":"GUARDRAIL: rm -rf on system/home directories is blocked. Only project-relative paths are allowed."}' >&2
    exit 2
  fi
fi

# --- Docker destructive commands ---
if echo "$CMD" | grep -qE 'docker\s+(system\s+prune|volume\s+prune|image\s+prune\s+-a)'; then
  echo '{"decision":"block","reason":"GUARDRAIL: docker prune commands are blocked. These remove all unused resources."}' >&2
  exit 2
fi

# --- chmod 777 recursive ---
if echo "$CMD" | grep -qE 'chmod\s+.*-R.*777|chmod\s+777\s+.*-R'; then
  echo '{"decision":"block","reason":"GUARDRAIL: chmod -R 777 is blocked. This makes all files world-writable."}' >&2
  exit 2
fi

# --- Package publishing ---
if echo "$CMD" | grep -qE '(npm|pnpm|yarn)\s+publish'; then
  echo '{"decision":"block","reason":"GUARDRAIL: package publishing is blocked. Publish manually."}' >&2
  exit 2
fi

# --- ORM schema push protection (causes schema drift) ---
# Prisma: must use prisma migrate dev (not db push)
# Drizzle: must use drizzle-kit generate + drizzle-kit migrate (not drizzle-kit push)
if echo "$CMD" | grep -qE '(prisma\s+db\s+push|drizzle-kit\s+push|db:push)'; then
  echo '{"decision":"block","reason":"GUARDRAIL: Direct schema push is blocked (causes database drift with no migration history). Use proper migrations instead: Prisma: `pnpm db:migrate` (prisma migrate dev) | Drizzle: `drizzle-kit generate` then `drizzle-kit migrate`."}' >&2
  exit 2
fi

# --- Drop database ---
if echo "$CMD" | grep -qiE '(drop\s+database|drop\s+schema|truncate)'; then
  echo '{"decision":"block","reason":"GUARDRAIL: destructive database commands (DROP/TRUNCATE) are blocked."}' >&2
  exit 2
fi

# --- curl with destructive HTTP methods to production ---
if echo "$CMD" | grep -qE 'curl\s+.*-X\s*(DELETE|PUT|PATCH).*prod'; then
  echo '{"decision":"block","reason":"GUARDRAIL: destructive HTTP methods against production URLs are blocked."}' >&2
  exit 2
fi

# All checks passed
exit 0
