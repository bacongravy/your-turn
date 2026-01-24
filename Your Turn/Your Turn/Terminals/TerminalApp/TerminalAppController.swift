//
//  TerminalAppController.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import AppKit
import Foundation
import os.log

/// Controller for Terminal.app activation.
/// Terminal.app does not support session-level focus, so we only activate the application.
@MainActor
final class TerminalAppController: TerminalActivating {
    static let shared = TerminalAppController()
    private let logger = Logger(subsystem: "net.bacongravy.Your-Turn", category: "TerminalAppController")
    private let bundleId = "com.apple.Terminal"

    private init() {}

    func isRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleId
        }
    }

    /// Activate Terminal.app.
    /// - Parameter sessionId: Ignored. Terminal.app does not expose session IDs.
    func activate(sessionId: String?) {
        guard isRunning() else {
            logger.debug("Terminal.app not running, skipping activation")
            return
        }

        let script = """
            tell application "Terminal"
                activate
            end tell
            """
        executeScript(script)
    }

    private func executeScript(_ source: String) {
        guard let script = NSAppleScript(source: source) else {
            logger.error("Failed to create AppleScript")
            return
        }

        var errorInfo: NSDictionary?
        _ = script.executeAndReturnError(&errorInfo)

        if let error = errorInfo {
            logger.debug("AppleScript error: \(error)")
        }
    }
}
