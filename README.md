# Your Turn

<p align="center">
  <img src="docs/app-icon.png" alt="Your Turn" width="128" height="128">
</p>

<p align="center">
  <strong>Find out when it's your turn. One click to pick up where you left off.</strong>
</p>

<p align="center">
  A macOS menu bar app that notifies you when Claude Code needs your attention and brings the right terminal session to front with one click.
</p>

---

## The Problem

When working with Claude Code, you often need to step away while it thinks, writes code, or runs commands. But Claude frequently pauses to ask questions or request permissions. Without constant monitoring, you miss these moments and waste time waiting for work that's already done.

## The Solution

**Your Turn** watches your Claude Code sessions and notifies you the moment they need attention:

- **Task Complete** — Claude finished the work
- **Input Needed** — Claude is asking a question or needs permission

Click the notification and Your Turn brings your terminal directly to the session that needs you—no hunting through tabs or windows.

## Features

- **Smart Notifications** — Get notified only when action is needed, not for every Claude message
- **One-Click Focus** — Click a notification to jump directly to the right terminal session
- **Multi-Terminal Support** — Works with iTerm2, Terminal.app, and Warp
- **Customizable Sounds** — Choose from 18 classic Mac sounds with adjustable repeat count
- **Lightweight** — Lives in your menu bar, uses minimal resources
- **Privacy-First** — All processing happens locally; no data leaves your machine

## Requirements

- macOS 15.0 (Sequoia) or later
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed

## Installation

### Download

1. Download the latest release from the [Releases](https://github.com/bacongravy/your-turn/releases) page
2. Move `Your Turn.app` to your Applications folder
3. Launch the app and follow the setup wizard

### Setup Wizard

On first launch, Your Turn guides you through:

1. **Installing Hooks** — Configures Claude Code to send events to Your Turn
2. **Notification Permission** — Enables macOS notifications
3. **Terminal Integration** — Grants permission to activate your terminal
4. **Launch at Login** — Optionally start Your Turn when you log in

That's it! Your Turn is now monitoring your Claude Code sessions.

## Usage

Once set up, Your Turn runs silently in your menu bar. When Claude Code needs attention:

1. You'll hear a notification sound (configurable)
2. A macOS notification appears with context about what happened
3. Click the notification to jump directly to that terminal session

### Menu Bar

Click the menu bar icon to:

- Open Settings
- Quit the app

### Settings

Access settings from the menu bar to configure:

- **Notifications** — Sound selection and repeat count
- **Events** — Choose which events trigger notifications
- **General** — Launch at login preference
- **Health** — View integration status

## How It Works

```
Claude Code Hook → Shell Script → Unix Socket → Your Turn → macOS Notification
                                                    ↓
                                            Click → AppleScript → Terminal
```

1. Claude Code emits lifecycle events via its hooks system
2. A shell script forwards these events to Your Turn via Unix socket
3. Your Turn posts a macOS notification with relevant context
4. Clicking the notification runs AppleScript to focus the correct terminal session

## Terminal Support

| Terminal | Focus Support | Notes |
|----------|--------------|-------|
| iTerm2 | Full | Focuses exact session via TERM_SESSION_ID |
| Terminal.app | Full | Matches session by TTY |
| Warp | Basic | Brings app to front |

## Development

### Prerequisites

- Xcode 16.0 or later
- macOS 15.0 or later

### Building

```bash
# Clone the repository
git clone https://github.com/bacongravy/your-turn.git
cd your-turn

# Build
./Scripts/build.sh

# Build and run
./Scripts/build.sh run

# Build and debug with lldb
./Scripts/build.sh debug
```

### Testing

```bash
# Send test events to the app
./Scripts/test-socket.sh permission  # Simulate permission prompt
./Scripts/test-socket.sh mcp         # Simulate MCP tool input dialog
./Scripts/test-socket.sh stop        # Simulate task complete

# Reset app state for fresh testing
./Scripts/reset-for-testing.sh
```

### Project Structure

```
Sources/
├── App/                    # App lifecycle & socket server
├── Hooks/                  # Claude Code hook installation
├── Features/               # Notifications & health monitoring
├── Terminals/              # Terminal integrations (iTerm2, Terminal.app, Warp)
├── Models/                 # Data models
├── Views/                  # SwiftUI views (Settings, Setup Wizard)
└── Resources/              # Hook script & bundled sounds
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- Classic Mac sounds from macOS system library
