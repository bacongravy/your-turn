#!/bin/bash
#
# debug.sh - Launch app in lldb with auto-run and clean exit handling
#
# Usage: ./Scripts/debug.sh <app-path>
#
# Features:
#   - Auto-runs the app (no need to type "run")
#   - ctrl-c pauses the process
#   - Auto-exits lldb when app terminates cleanly
#   - Stays interactive on crash for debugging
#

set -e

APP_PATH="$1"

if [ -z "$APP_PATH" ]; then
    echo "Usage: $0 <app-path>" >&2
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found: $APP_PATH" >&2
    exit 1
fi

# Python monitor: auto-exit on clean termination (status 0) or kill (signals 9,15)
# Stays interactive on crash for debugging
LLDB_MONITOR='script import threading,time,os;d=lldb.debugger;threading.Thread(target=lambda:[time.sleep(.5)or(lambda p:p and p.GetState()==10 and(p.GetExitStatus()==0 or p.GetSignal()in[9,15])and os._exit(0))((lambda t:t.GetProcess()if t else None)(d.GetSelectedTarget()))for _ in iter(int,1)],daemon=True).start()'

# Expect script for proper pty handling (process substitution keeps stdin free)
LLDB_MONITOR="$LLDB_MONITOR" expect -f <(cat << 'EOF'
set app [lindex $argv 0]
spawn lldb -o $env(LLDB_MONITOR) $app
expect "(lldb) "
send "run\r"
interact
EOF
) "$APP_PATH"
