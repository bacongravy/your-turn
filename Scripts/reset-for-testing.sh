#!/bin/bash
# Reset Your Turn app state and permissions for testing first-launch experience
#
# Note: tccutil may require Terminal to have Full Disk Access
# (System Settings > Privacy & Security > Full Disk Access)

set -e

BUNDLE_ID="net.bacongravy.Your-Turn"
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOK_SCRIPT="$HOME/.claude/hooks/your-turn-notify.sh"
PLIST_FILE="$HOME/Library/Preferences/${BUNDLE_ID}.plist"

echo "Resetting Your Turn for fresh testing..."

# Kill the app if running
echo "  Stopping app if running..."
killall "Your Turn" 2>/dev/null || true

# Reset app preferences (UserDefaults)
# Use plist path directly because defaults may look in wrong location
# (Containers vs regular Preferences) after sandbox changes
echo "  Resetting preferences..."
if [ -f "$PLIST_FILE" ]; then
  defaults delete "$PLIST_FILE" 2>/dev/null || rm "$PLIST_FILE"
  echo "    Removed $PLIST_FILE"
else
  echo "    No preferences file found"
fi

# Force preferences daemon to reload
killall cfprefsd 2>/dev/null || true

# Reset notification permission
echo "  Resetting notification permission..."
tccutil reset Notifications "$BUNDLE_ID" 2>/dev/null || true

# Try to remove from notification center preferences
NC_PREFS="$HOME/Library/Preferences/com.apple.ncprefs.plist"
if [ -f "$NC_PREFS" ]; then
  # Find and remove our app's entry from the apps array
  # The plist has an 'apps' array with dictionaries containing 'bundle-id' keys
  INDEX=$(/usr/libexec/PlistBuddy -c "Print apps" "$NC_PREFS" 2>/dev/null | grep -n "bundle-id = $BUNDLE_ID" | cut -d: -f1 | head -1)
  if [ -n "$INDEX" ]; then
    # PlistBuddy arrays are 0-indexed, grep line numbers are 1-indexed
    # We need to find the Dict index, not the line number
    # Iterate through apps to find matching bundle-id
    i=0
    while true; do
      BID=$(/usr/libexec/PlistBuddy -c "Print apps:$i:bundle-id" "$NC_PREFS" 2>/dev/null) || break
      if [ "$BID" = "$BUNDLE_ID" ]; then
        echo "  Removing from Notification Center preferences (index $i)..."
        /usr/libexec/PlistBuddy -c "Delete apps:$i" "$NC_PREFS" 2>/dev/null || true
        # Restart notification center to pick up changes
        killall NotificationCenter 2>/dev/null || true
        break
      fi
      i=$((i + 1))
    done
  fi
fi

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
