#!/bin/bash
# Store notarization credentials in keychain
# Reads all values from stdin

set -e

PROFILE_NAME="${NOTARY_PROFILE:-your-turn-notary}"

echo "Store notarization credentials"
echo "=============================="
echo "Profile name: $PROFILE_NAME"
echo "(Override with NOTARY_PROFILE env var)"
echo ""

read -p "Team ID: " TEAM_ID
read -p "Apple ID: " APPLE_ID
read -s -p "App-specific password: " APP_PASSWORD
echo ""

if [[ -z "$TEAM_ID" || -z "$APPLE_ID" || -z "$APP_PASSWORD" ]]; then
    echo "Error: All fields are required"
    exit 1
fi

echo ""
echo "Storing credentials in keychain..."

xcrun notarytool store-credentials "$PROFILE_NAME" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD"

echo "✓ Credentials stored as '$PROFILE_NAME'"
echo ""
echo "Use with: xcrun notarytool submit <file> --keychain-profile \"$PROFILE_NAME\""
