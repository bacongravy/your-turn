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
Your Turn/
├── Your_TurnApp.swift      # App entry point, menu bar setup
├── Services/
│   ├── AppDelegate.swift       # Window management, notification delegate
│   ├── SocketServer.swift      # Unix socket listener, JSON parsing
│   ├── NotificationService.swift   # Event → notification logic
│   ├── SoundPlayer.swift       # App-controlled sound playback with repeat
│   ├── HookInstaller.swift     # Installs hooks into ~/.claude/settings.json
│   ├── HealthCheckService.swift    # Integration health monitoring
│   ├── ITermController.swift   # iTerm2 AppleScript control (session switching)
│   ├── ITerm2.swift            # iTerm2 shell integration detection
│   ├── TerminalController.swift    # Protocol for terminal controllers
│   ├── TerminalAppController.swift # Terminal.app AppleScript control
│   └── WarpController.swift    # Warp terminal control (basic)
├── Models/
│   ├── HookEvent.swift         # JSON event model from Claude Code
│   ├── SystemSound.swift       # Sound picker data model
│   └── HealthStatus.swift      # Integration health states
├── Views/
│   ├── SettingsView.swift      # Main settings window (tab container)
│   ├── GeneralSection.swift    # Launch at login settings
│   ├── NotificationSection.swift   # Sound and notification preferences
│   ├── EventsSection.swift     # Per-event notification toggles
│   ├── HealthStatusSection.swift   # Integration health display
│   ├── AboutSection.swift      # App version and about info
│   ├── ToggleRow.swift         # Reusable toggle row component
│   └── SetupWizard/
│       ├── SetupWizardView.swift   # Wizard container and navigation
│       ├── WizardStepLayout.swift  # Common step layout component
│       ├── WelcomeStep.swift       # Welcome/intro step
│       ├── HooksStep.swift         # Hook installation step
│       ├── NotificationsStep.swift # Notification permission step
│       ├── ITermIntegrationStep.swift  # iTerm2 shell integration step
│       ├── LaunchAtLoginStep.swift # Login item setup step
│       └── CompleteStep.swift      # Setup complete summary
└── Resources/
    ├── your-turn-notify.sh     # Hook script (deployed to ~/.claude/hooks/)
    └── Sounds/                 # Classic Mac sounds (18 bundled .aiff files)
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
| `notify.permission` | Bool | true | Notify on permission requests |
| `notify.inputNeeded` | Bool | true | Notify when input needed |
| `notify.taskComplete` | Bool | false | Notify on task complete |
| `notify.error` | Bool | false | Notify on errors |

## Development

### Build Environment Detection

When the current user is `claude`, you are in a limited environment without keychain access for code signing.

**Detect limited environment:**
```bash
whoami  # Returns 'claude' in limited environment
```

**Build in limited environment (no signing):**
```bash
cd "Your Turn"
xcodebuild -scheme "Your Turn" -configuration Debug build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

**Build in full environment (with signing):**
```bash
cd "Your Turn"
xcodebuild -scheme "Your Turn" -configuration Debug build
```

### SourceKit False Positives

SourceKit (Swift language server) often reports false errors when editing files because it cannot see the full project context:

- `Cannot find 'TypeName' in scope` - Type exists in another project file
- `Cannot find type 'ProtocolName' in scope` - Protocol exists in project
- `Cannot infer type of closure parameter` - Type available at compile time

**How to handle:**
1. Do not trust SourceKit diagnostics alone
2. Always verify with actual `xcodebuild`
3. If build succeeds, SourceKit errors are false positives

### Scripts

Utility scripts in `scripts/`:
- `test-socket.sh` - Send test events to the Unix socket
- `reset-for-testing.sh` - Reset app state for fresh testing
- `generate-menu-icon.swift` - Generate menu bar icon assets

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
