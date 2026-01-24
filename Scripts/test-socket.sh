#!/bin/bash
#
# test-socket.sh - Send test events to Your Turn socket
#
# Usage:
#   ./Scripts/test-socket.sh                    # Send permission_prompt event
#   ./Scripts/test-socket.sh permission         # Send permission_prompt event
#   ./Scripts/test-socket.sh input              # Send input_needed event
#   ./Scripts/test-socket.sh stop               # Send Stop event
#   ./Scripts/test-socket.sh error              # Send error notification
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
    echo "  permission    Send permission_prompt event (default)"
    echo "  input         Send input_needed event"
    echo "  stop          Send Stop event (task complete)"
    echo "  error         Send error notification"
    echo ""
    echo "Options:"
    echo "  --help        Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  TERM_PROGRAM      Terminal app name (default: iTerm.app)"
    echo "  TERM_SESSION_ID   Terminal session ID (default: test-term-session)"
    echo ""
    echo "Examples:"
    echo "  $0                              # Send permission event (iTerm.app)"
    echo "  $0 input                        # Send input needed event"
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
CWD="${PWD}"
PROJECT_NAME=$(basename "$CWD")

# Parse arguments
EVENT_TYPE="${1:-permission}"

case "$EVENT_TYPE" in
    --help|-h)
        usage
        exit 0
        ;;
    permission)
        check_socket
        JSON=$(cat <<EOF
{
    "session_id": "$SESSION_ID",
    "cwd": "$CWD",
    "hook_event_name": "PreToolUse",
    "tool_name": "Bash",
    "tool_input": {
        "command": "rm -rf /important/data",
        "description": "Delete important data"
    },
    "term_session_id": "$TERM_SESSION_ID",
    "term_program": "$TERM_PROGRAM"
}
EOF
)
        send_event "$JSON" "permission_prompt"
        echo ""
        echo "Event details:"
        echo "  Type: permission_prompt (PreToolUse)"
        echo "  Tool: Bash"
        echo "  Project: $PROJECT_NAME"
        ;;
    input)
        check_socket
        JSON=$(cat <<EOF
{
    "session_id": "$SESSION_ID",
    "cwd": "$CWD",
    "hook_event_name": "Notification",
    "notification_type": "user",
    "message": "What color theme would you like?",
    "term_session_id": "$TERM_SESSION_ID",
    "term_program": "$TERM_PROGRAM"
}
EOF
)
        send_event "$JSON" "input_needed"
        echo ""
        echo "Event details:"
        echo "  Type: input_needed (user notification)"
        echo "  Message: What color theme would you like?"
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
    "term_program": "$TERM_PROGRAM"
}
EOF
)
        send_event "$JSON" "task_complete"
        echo ""
        echo "Event details:"
        echo "  Type: task_complete (Stop)"
        echo "  Project: $PROJECT_NAME"
        ;;
    error)
        check_socket
        JSON=$(cat <<EOF
{
    "session_id": "$SESSION_ID",
    "cwd": "$CWD",
    "hook_event_name": "Notification",
    "notification_type": "error",
    "message": "Build failed: 3 errors found",
    "term_session_id": "$TERM_SESSION_ID",
    "term_program": "$TERM_PROGRAM"
}
EOF
)
        send_event "$JSON" "error"
        echo ""
        echo "Event details:"
        echo "  Type: error notification"
        echo "  Message: Build failed: 3 errors found"
        echo "  Project: $PROJECT_NAME"
        ;;
    *)
        echo -e "${RED}Unknown event type:${NC} $EVENT_TYPE"
        echo ""
        usage
        exit 1
        ;;
esac
