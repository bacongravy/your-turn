//
//  ITermController.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import AppKit
import Foundation
import os.log

/// Controller for iTerm2 AppleScript automation.
/// Focuses terminal sessions by unique ID when users click notifications.
@MainActor
final class ITermController {
    static let shared = ITermController()
    private let logger = Logger(subsystem: "net.bacongravy.Your-Turn", category: "ITermController")
    private let iTerm2BundleId = "com.googlecode.iterm2"

    private init() {}

    /// Focus a specific iTerm2 session by its unique ID.
    /// Falls back to activating iTerm2 without session focus if session not found.
    /// - Parameter termSessionId: The TERM_SESSION_ID value (format: wXtYpZ:UUID)
    func focusSession(termSessionId: String) {
        guard isRunning() else {
            logger.debug("iTerm2 not running, skipping focus")
            return
        }

        // Extract UUID from TERM_SESSION_ID format "wXtYpZ:UUID"
        // The wXtYpZ prefix encodes window/tab/pane position, but AppleScript
        // uses only the UUID portion as the session's "unique id"
        let sessionUUID = extractSessionUUID(from: termSessionId)

        // AppleScript iterates all windows/tabs/sessions to find match
        // Uses set index + do shell script "open -a iTerm" for surgical window raising
        // NOTE: the order of the select and set index calls is important
        let script = """
            tell application "iTerm2"
                repeat with aWindow in windows
                    repeat with aTab in tabs of aWindow
                        repeat with aSession in sessions of aTab
                            if unique id of aSession is "\(sessionUUID)" then
                                select aTab
                                select aSession
                                set index of aWindow to 1
                                do shell script "open -a iTerm"
                                return true
                            end if
                        end repeat
                    end repeat
                end repeat
                activate
                return false
            end tell
            """
        executeScript(script)
    }

    /// Activate iTerm2 without focusing a specific session.
    /// Used when termSessionId is missing but termProgram indicates iTerm.
    func activateiTerm() {
        guard isRunning() else {
            logger.debug("iTerm2 not running, skipping activation")
            return
        }

        let script = """
            tell application "iTerm2"
                activate
            end tell
            """
        executeScript(script)
    }

    /// Extract the UUID portion from TERM_SESSION_ID.
    /// Format: "wXtYpZ:UUID" where wXtYpZ is window/tab/pane position.
    /// Returns the full string if no colon found (defensive fallback).
    private func extractSessionUUID(from termSessionId: String) -> String {
        if let colonIndex = termSessionId.firstIndex(of: ":") {
            return String(termSessionId[termSessionId.index(after: colonIndex)...])
        }
        return termSessionId
    }

    /// Check if iTerm2 is currently running.
    func isRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == iTerm2BundleId
        }
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

// MARK: - TerminalActivating

extension ITermController: TerminalActivating {
    /// Activate iTerm2, optionally focusing a specific session.
    /// - Parameter sessionId: The TERM_SESSION_ID value (format: wXtYpZ:UUID), or nil.
    func activate(sessionId: String?) {
        if let sessionId = sessionId, !sessionId.isEmpty {
            focusSession(termSessionId: sessionId)
        } else {
            activateiTerm()
        }
    }
}
