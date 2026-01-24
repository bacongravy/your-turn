#!/bin/bash
#
# test-socket.sh - Send test events to Your Turn socket
#
# Usage:
#   ./Scripts/test-socket.sh                    # Send permission_prompt event
#   ./Scripts/test-socket.sh input              # Send permission_prompt event
#   ./Scripts/test-socket.sh mcp                # Send elicitation_dialog event
#   ./Scripts/test-socket.sh idle               # Send idle_prompt event
#   ./Scripts/test-socket.sh stop               # Send Stop event
#   ./Scripts/test-socket.sh --help             # Show usage
#
# The app must be running for this to work.

set -e

SOCKET_PATH="$HOME/Library/Application Support/Your Turn/claude-notify.sock"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [event_type]"
    echo ""
    echo "Event types:"
    echo "  input         Send permission_prompt event (default)"
    echo "  mcp           Send elicitation_dialog event (MCP tool input)"
    echo "  idle          Send idle_prompt event (60s waiting)"
    echo "  stop          Send Stop event (task complete)"
    echo ""
    echo "Options:"
    echo "  --help        Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  TERM_PROGRAM      Terminal app name (default: iTerm.app)"
    echo "  TERM_SESSION_ID   Terminal session ID (default: test-term-session)"
    echo ""
    echo "Examples:"
    echo "  $0                              # Send input event (iTerm.app)"
    echo "  $0 mcp                          # Send MCP elicitation event"
    echo "  $0 idle                         # Send idle prompt event"
    echo "  TERM_PROGRAM=Apple_Terminal $0  # Test Terminal.app activation"
    echo "  TERM_PROGRAM=WarpTerminal $0    # Test Warp activation"
}

check_socket() {
    if [ ! -S "$SOCKET_PATH" ]; then
        echo -e "${RED}Error:${NC} Socket not found at:"
        echo "  $SOCKET_PATH"
        echo ""
        echo "Make sure Your Turn app is running."
        exit 1
    fi
}

send_event() {
    local json="$1"
    local event_type="$2"

    echo -e "${YELLOW}Sending ${event_type} event...${NC}"
    echo "$json" | nc -U "$SOCKET_PATH"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Sent successfully${NC}"
    else
        echo -e "${RED}Failed to send${NC}"
        exit 1
    fi
}

# Generate a unique session ID for testing
SESSION_ID="test-$(date +%s)"
TERM_SESSION_ID="${TERM_SESSION_ID:-test-term-session}"
TERM_PROGRAM="${TERM_PROGRAM:-iTerm.app}"
TTY_PATH=$(tty 2>/dev/null || echo "/dev/ttys000")
CWD="${PWD}"
PROJECT_NAME=$(basename "$CWD")

# Parse arguments
EVENT_TYPE="${1:-input}"

case "$EVENT_TYPE" in
    --help|-h)
        usage
        exit 0
        ;;
    input)
        check_socket
        JSON=$(cat <<EOF
{
    "session_id": "$SESSION_ID",
    "cwd": "$CWD",
    "hook_event_name": "Notification",
    "notification_type": "permission_prompt",
    "message": "Claude Code wants to run: rm -rf /important/data",
    "term_session_id": "$TERM_SESSION_ID",
    "term_program": "$TERM_PROGRAM",
    "tty": "$TTY_PATH"
}
EOF
)
        send_event "$JSON" "permission_prompt"
        echo ""
        echo "Event details:"
        echo "  Type: Notification (permission_prompt)"
        echo "  Message: Claude Code wants to run: rm -rf /important/data"
        echo "  Project: $PROJECT_NAME"
        ;;
    mcp)
        check_socket
        JSON=$(cat <<EOF
{
    "session_id": "$SESSION_ID",
    "cwd": "$CWD",
    "hook_event_name": "Notification",
    "notification_type": "elicitation_dialog",
    "message": "MCP tool needs your input",
    "term_session_id": "$TERM_SESSION_ID",
    "term_program": "$TERM_PROGRAM",
    "tty": "$TTY_PATH"
}
EOF
)
        send_event "$JSON" "elicitation_dialog"
        echo ""
        echo "Event details:"
        echo "  Type: Notification (elicitation_dialog)"
        echo "  Message: MCP tool needs your input"
        echo "  Project: $PROJECT_NAME"
        ;;
    idle)
        check_socket
        JSON=$(cat <<EOF
{
    "session_id": "$SESSION_ID",
    "cwd": "$CWD",
    "hook_event_name": "Notification",
    "notification_type": "idle_prompt",
    "message": "Claude Code has been waiting for input",
    "term_session_id": "$TERM_SESSION_ID",
    "term_program": "$TERM_PROGRAM",
    "tty": "$TTY_PATH"
}
EOF
)
        send_event "$JSON" "idle_prompt"
        echo ""
        echo "Event details:"
        echo "  Type: Notification (idle_prompt)"
        echo "  Message: Claude Code has been waiting for input"
        echo "  Project: $PROJECT_NAME"
        ;;
    stop)
        check_socket
        JSON=$(cat <<EOF
{
    "session_id": "$SESSION_ID",
    "cwd": "$CWD",
    "hook_event_name": "Stop",
    "stop_hook_active": true,
    "term_session_id": "$TERM_SESSION_ID",
    "term_program": "$TERM_PROGRAM",
    "tty": "$TTY_PATH"
}
EOF
)
        send_event "$JSON" "task_complete"
        echo ""
        echo "Event details:"
        echo "  Type: Stop"
        echo "  Project: $PROJECT_NAME"
        ;;
    *)
        echo -e "${RED}Unknown event type:${NC} $EVENT_TYPE"
        echo ""
        usage
        exit 1
        ;;
esac
