#!/bin/bash
# Reset Your Turn app state and permissions for testing first-launch experience
#
# Note: tccutil may require Terminal to have Full Disk Access
# (System Settings > Privacy & Security > Full Disk Access)

set -e

BUNDLE_ID="net.bacongravy.Your-Turn"

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

echo "Done. You can now run the app to test the setup wizard."
