# Your Turn

A macOS menu bar app that notifies you when Claude Code needs attention and brings the right terminal session to front with one click.

## What It Does

When Claude Code stops working (needs input, permission, done, or error), the app:
1. Receives the event via Unix socket from a hook script
2. Posts a macOS notification with context (event type, project name)
3. Plays a sound (configurable, with repeat count)
4. Clicking the notification focuses the correct terminal session

## Architecture

```
Claude Code Hook → Shell Script → Unix Socket → Your Turn App → macOS Notification
                                                      ↓
                                              Click → AppleScript → iTerm2/Terminal
```

### Source Structure

```
Sources/
├── Your_TurnApp.swift          # App entry point, menu bar setup
├── App/                        # App lifecycle & infrastructure
│   ├── AppDelegate.swift           # Window management, notification delegate
│   └── SocketServer.swift          # Unix socket listener, JSON parsing
├── Hooks/                      # AI agent hook integrations
│   └── HookInstaller.swift         # Claude Code hook installation
├── Features/                   # Feature modules
│   ├── Notifications/
│   │   ├── NotificationService.swift   # Event → notification logic
│   │   └── SoundPlayer.swift           # App-controlled sound playback
│   └── HealthCheck/
│       ├── HealthCheckService.swift    # Integration health monitoring
│       └── HealthStatus.swift          # Health state model
├── Terminals/                  # Terminal integrations
│   ├── TerminalController.swift    # Protocol + registry
│   ├── AppleScriptRunner.swift     # Shared AppleScript utilities
│   ├── ITerm/
│   │   ├── ITerm2.swift                # Centralized iTerm2 logic
│   │   └── ITermController.swift       # TerminalActivating adapter
│   ├── TerminalApp/
│   │   ├── TerminalApp.swift           # Centralized Terminal.app logic
│   │   └── TerminalAppController.swift # TerminalActivating adapter
│   └── Warp/
│       ├── Warp.swift                  # Centralized Warp logic
│       └── WarpController.swift        # TerminalActivating adapter
├── Models/                     # Data models
│   ├── HookEvent.swift             # JSON event model from Claude Code
│   └── SystemSound.swift           # Sound picker data model
├── Views/                      # UI layer
│   ├── Settings/
│   │   ├── SettingsView.swift          # Main settings window (tabs)
│   │   ├── GeneralSection.swift        # Launch at login settings
│   │   ├── NotificationSection.swift   # Sound preferences
│   │   ├── EventsSection.swift         # Per-event toggles
│   │   ├── HealthStatusSection.swift   # Health display
│   │   └── AboutSection.swift          # App version info
│   ├── SetupWizard/
│   │   ├── SetupWizardView.swift       # Wizard container
│   │   ├── WizardStepLayout.swift      # Common step layout
│   │   ├── WelcomeStep.swift           # Welcome/intro step
│   │   ├── HooksStep.swift             # Hook installation step
│   │   ├── NotificationsStep.swift     # Notification permission step
│   │   ├── TerminalAppIntegrationStep.swift  # Terminal.app integration step
│   │   ├── ITermIntegrationStep.swift  # iTerm2 integration step
│   │   ├── LaunchAtLoginStep.swift     # Login item setup step
│   │   └── CompleteStep.swift          # Setup complete summary
│   └── Components/
│       ├── ToggleRow.swift                 # Reusable toggle component
│       ├── NotificationGuidanceSheet.swift # System Settings guidance for notifications
│       └── AutomationGuidanceSheet.swift   # System Settings guidance for automation
└── Resources/
    ├── your-turn-notify.sh         # Hook script (deployed to ~/.claude/hooks/)
    └── Sounds/                     # Classic Mac sounds (18 bundled .aiff files)
```

### Key Files

- **Unix Socket**: `~/Library/Application Support/Your Turn/claude-notify.sock`
- **Hook Script**: `~/.claude/hooks/your-turn-notify.sh` (deployed by app)
- **Claude Settings**: `~/.claude/settings.json` (hooks registered here)

### UserDefaults Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `setupComplete` | Bool | false | First-launch wizard completed |
| `notify.enabled` | Bool | true | Master toggle for notifications |
| `notify.soundEnabled` | Bool | true | Enable/disable sound playback |
| `notify.sound` | String | "Sosumi.aiff" | Notification sound filename |
| `notify.soundRepeatCount` | Int | 1 | Times to play sound (1-5) |
| `notify.taskComplete` | Bool | true | Notify on task complete (Stop) |
| `notify.inputNeeded` | Bool | true | Notify when input needed (permission_prompt, elicitation_dialog) |
| `notify.idle` | Bool | false | Notify after 60s idle (idle_prompt) |

## Development

### Building

Always use `./Scripts/build.sh` instead of running xcodebuild directly. The script automatically detects if code signing is available and adjusts accordingly.

### SourceKit False Positives

SourceKit (Swift language server) often reports false errors when editing files because it cannot see the full project context:

- `Cannot find 'TypeName' in scope` - Type exists in another project file
- `Cannot find type 'ProtocolName' in scope` - Protocol exists in project
- `Cannot infer type of closure parameter` - Type available at compile time

**How to handle:**
1. Do not trust SourceKit diagnostics alone
2. Always verify with `./Scripts/build.sh`
3. If build succeeds, SourceKit errors are false positives

### Scripts

Utility scripts in `Scripts/`:

| Script | Usage | Description |
|--------|-------|-------------|
| `build.sh` | `./Scripts/build.sh [command]` | **Primary build script** - always use this instead of xcodebuild directly |
| `debug.sh` | (called by build.sh) | Launch app in lldb with auto-run |
| `test-socket.sh` | `./Scripts/test-socket.sh` | Send test events to the Unix socket |
| `reset-for-testing.sh` | `./Scripts/reset-for-testing.sh` | Reset app state for fresh testing |
| `generate-menu-icon.swift` | `swift Scripts/generate-menu-icon.swift` | Generate menu bar icon assets |

**build.sh commands:**
- `./Scripts/build.sh` - Build only (default)
- `./Scripts/build.sh run` - Build and launch app
- `./Scripts/build.sh debug` - Build and launch with lldb
- `./Scripts/build.sh clean` - Remove build directory

The build script automatically detects if code signing is available and adjusts accordingly.

### Terminal Support

| Terminal | Focus Support | Notes |
|----------|--------------|-------|
| iTerm2 | Full | TERM_SESSION_ID for exact session |
| Terminal.app | Full | AppleScript with tty matching |
| Warp | Basic | Brings app to front only |

## Constraints

- **macOS only** - Uses AppKit, UserNotifications, AppleScript
- **Not App Store** - Requires Unix socket (sandbox incompatible)
- **Swift/SwiftUI** - Modern Swift with SwiftUI for settings UI
- **No third-party deps** - Native frameworks only
