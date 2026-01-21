#!/bin/bash
# Reset Your Turn app state and permissions for testing first-launch experience
#
# Note: tccutil may require Terminal to have Full Disk Access
# (System Settings > Privacy & Security > Full Disk Access)

set -e

BUNDLE_ID="net.bacongravy.Your-Turn"
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOK_SCRIPT="$HOME/.claude/hooks/your-turn-notify.sh"

echo "Resetting Your Turn for fresh testing..."

# Reset app preferences (UserDefaults)
echo "  Resetting preferences..."
defaults delete "$BUNDLE_ID" 2>/dev/null || true

# Reset notification permission
echo "  Resetting notification permission..."
tccutil reset Notifications "$BUNDLE_ID" 2>/dev/null || true

# Reset automation permission (AppleScript)
echo "  Resetting automation permission..."
tccutil reset AppleEvents "$BUNDLE_ID" 2>/dev/null || true

# Remove hook script
if [ -f "$HOOK_SCRIPT" ]; then
  echo "  Removing hook script..."
  rm "$HOOK_SCRIPT"
fi

# Remove hooks from settings.json
if [ -f "$SETTINGS_FILE" ]; then
  if command -v jq &>/dev/null; then
    echo "  Removing hooks from settings.json..."
    # Remove Notification and Stop hooks that reference our script
    jq '
      if .hooks then
        .hooks |= (
          if .Notification then
            .Notification |= map(select(.hooks | all(.command | contains("your-turn-notify.sh") | not)))
            | if .Notification == [] then del(.Notification) else . end
          else . end
          |
          if .Stop then
            .Stop |= map(select(.hooks | all(.command | contains("your-turn-notify.sh") | not)))
            | if .Stop == [] then del(.Stop) else . end
          else . end
        )
        | if .hooks == {} then del(.hooks) else . end
      else . end
    ' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp" && mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
  else
    echo "  WARNING: jq not installed, skipping settings.json cleanup"
    echo "           Install with: brew install jq"
  fi
fi

echo "Done. You can now run the app to test the setup wizard."
