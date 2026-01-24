#!/bin/bash
# Hook script for Your Turn - forwards Claude Code events to Unix socket
# Deployed to ~/.claude/hooks/ by Your Turn app

SOCKET_PATH="$HOME/Library/Application Support/Your Turn/claude-notify.sock"

# Exit silently if socket doesn't exist (app not running)
[ ! -S "$SOCKET_PATH" ] && exit 0

# Read JSON from stdin (Claude Code provides hook event data)
INPUT=$(cat)

# Add terminal environment variables, project dir, and tty to JSON
# This enables smart suppression and terminal focusing features
TTY_PATH=$(tty 2>/dev/null || echo "")
if command -v jq &> /dev/null; then
    # jq available - use it for safe JSON manipulation
    OUTPUT=$(echo "$INPUT" | jq --arg tid "${TERM_SESSION_ID:-}" \
                                 --arg tprog "${TERM_PROGRAM:-}" \
                                 --arg tty "$TTY_PATH" \
                                 --arg projdir "${CLAUDE_PROJECT_DIR:-}" \
                                 '. + {term_session_id: $tid, term_program: $tprog, tty: $tty, project_dir: $projdir}')
else
    # jq not available - use sed for basic injection (less safe but works)
    # Insert before the final closing brace
    TERM_JSON="\"term_session_id\":\"${TERM_SESSION_ID:-}\",\"term_program\":\"${TERM_PROGRAM:-}\",\"tty\":\"$TTY_PATH\",\"project_dir\":\"${CLAUDE_PROJECT_DIR:-}\""
    OUTPUT=$(echo "$INPUT" | sed "s/}$/,$TERM_JSON}/")
fi

# Send to socket via netcat
echo "$OUTPUT" | nc -U "$SOCKET_PATH" 2>/dev/null

# Always exit 0 so Claude Code continues normally
exit 0
