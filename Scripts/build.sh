#!/bin/bash
#
# build.sh - Build Your Turn macOS app
#
# Usage:
#   ./Scripts/build.sh              # Build only (default)
#   ./Scripts/build.sh run          # Build and launch app
#   ./Scripts/build.sh debug        # Build and launch with lldb
#   ./Scripts/build.sh release      # Build Release configuration
#   ./Scripts/build.sh notarize     # Build, notarize, and create distribution ZIP
#   ./Scripts/build.sh clean        # Remove build directory
#   ./Scripts/build.sh help         # Show usage
#

set -e

# Project settings
PROJECT="YourTurn.xcodeproj"
SCHEME="Your Turn"
CONFIG="Debug"
BUILD_DIR="./build"
APP_PATH="$BUILD_DIR/Build/Products/Debug/Your Turn.app"

# Colors for output (bold to match xcbeautify)
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (none)    Build only (default)"
    echo "  run       Build and launch app"
    echo "  debug     Build and launch with lldb"
    echo "  release   Build Release configuration"
    echo "  notarize  Build, notarize, and create distribution ZIP"
    echo "  clean     Remove build directory"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                # Build the app"
    echo "  $0 run            # Build and launch"
    echo "  $0 debug          # Build and attach debugger"
    echo "  $0 release        # Build for release"
    echo "  $0 notarize       # Create notarized distribution"
    echo "  $0 clean          # Clean build artifacts"
}

build() {
    # Create empty Local.xcconfig if it doesn't exist (allows building without code signing)
    if [[ ! -f "Local.xcconfig" ]]; then
        echo "// Local.xcconfig - run Scripts/setup-local-config.sh to configure code signing" > Local.xcconfig
    fi

    # Detect limited environment (no keychain access for signing)
    local signing_args=()
    if security find-identity -v -p codesigning 2>/dev/null | grep -q "0 valid identities found"; then
        signing_args=(
            CODE_SIGN_IDENTITY=""
            CODE_SIGNING_REQUIRED=NO
            CODE_SIGNING_ALLOWED=NO
        )
    fi

    # Use xcbeautify if available, otherwise raw output
    local formatter="cat"
    if command -v xcbeautify &>/dev/null; then
        formatter="xcbeautify"
    fi

    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration "$CONFIG" \
        -derivedDataPath "$BUILD_DIR" \
        "${signing_args[@]}" \
        build | $formatter
}

kill_app() {
    # Kill running instance if present, ignore if not running
    pkill -x "Your Turn" 2>/dev/null || true
}

# Parse command
COMMAND="${1:-build}"

case "$COMMAND" in
    help|--help|-h)
        usage
        exit 0
        ;;
    build|"")
        build
        ;;
    run)
        build
        kill_app
        echo -e "${GREEN}App launching...${NC}"
        exec "$APP_PATH/Contents/MacOS/Your Turn"
        ;;
    debug)
        build
        kill_app
        "$(dirname "$0")/debug.sh" "$APP_PATH"
        ;;
    release)
        CONFIG="Release"
        APP_PATH="$BUILD_DIR/Build/Products/Release/Your Turn.app"
        build
        echo -e "${GREEN}Release build complete:${NC} $APP_PATH"
        ;;
    notarize)
        CONFIG="Release"
        APP_PATH="$BUILD_DIR/Build/Products/Release/Your Turn.app"
        ZIP_PATH="$BUILD_DIR/Build/Products/Release/Your-Turn.zip"
        NOTARY_PROFILE="${NOTARY_PROFILE:-your-turn-notary}"

        # Build
        build
        echo -e "${GREEN}Release build complete${NC}"

        # Create ZIP
        echo "Creating ZIP for notarization..."
        rm -f "$ZIP_PATH"
        ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

        # Submit for notarization
        echo "Submitting for notarization..."
        xcrun notarytool submit "$ZIP_PATH" \
            --keychain-profile "$NOTARY_PROFILE" \
            --wait

        # Staple
        echo "Stapling notarization ticket..."
        xcrun stapler staple "$APP_PATH"

        # Re-zip with stapled app
        echo "Creating final ZIP..."
        rm -f "$ZIP_PATH"
        ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

        # Verify
        echo "Verifying..."
        spctl --assess --type exec -vv "$APP_PATH"

        echo ""
        echo -e "${GREEN}Notarized ZIP ready:${NC} $ZIP_PATH"
        ;;
    clean)
        rm -rf "$BUILD_DIR"
        echo -e "${GREEN}Build directory cleaned${NC}"
        ;;
    *)
        echo -e "${RED}Unknown command:${NC} $COMMAND"
        echo ""
        usage
        exit 1
        ;;
esac
