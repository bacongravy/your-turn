//
//  ITerm2.swift
//  Your Turn
//
//  Consolidated iTerm2 integration logic.
//  All iTerm-related functionality is centralized here as static functions.
//

import AppKit
import Foundation
import os.log

/// Centralized iTerm2 integration logic.
/// All iTerm-related functionality exposed as static functions.
enum ITerm2 {
    private static let logger = Logger(subsystem: "net.bacongravy.Your-Turn", category: "ITerm2")

    // MARK: - Constants

    static let bundleIdentifier = "com.googlecode.iterm2"
    static let appName = "iTerm2"

    // MARK: - App State

    /// Check if iTerm2 is installed
    static func isInstalled() -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier:bundleIdentifier) != nil
    }

    /// Check if iTerm2 is currently running
    static func isRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleIdentifier
        }
    }

    /// Check if iTerm2 is the frontmost application
    static func isFrontmost() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        return frontmostApp.bundleIdentifier == bundleIdentifier
    }

    // MARK: - Session Management

    /// Extract the UUID portion from TERM_SESSION_ID.
    /// Format: "wXtYpZ:UUID" where wXtYpZ is window/tab/pane position.
    /// Returns the full string if no colon found (defensive fallback).
    static func extractSessionUUID(from termSessionId: String) -> String {
        if let colonIndex = termSessionId.firstIndex(of: ":") {
            return String(termSessionId[termSessionId.index(after: colonIndex)...])
        }
        return termSessionId
    }

    /// Get the unique ID of the current iTerm2 session via AppleScript
    static func getCurrentSessionId() -> String? {
        let script = """
            tell application "iTerm2"
                tell current session of current window
                    return unique id
                end tell
            end tell
            """

        let (result, error) = AppleScriptRunner.executeScript(script)

        if error != nil {
            // iTerm not running, no window, or other error - fail gracefully
            return nil
        }

        return result?.stringValue
    }

    /// Focus a specific iTerm2 session by its unique ID.
    /// Falls back to activating iTerm2 without session focus if session not found.
    /// Falls back to simple activation if automation permission is denied.
    /// - Parameter termSessionId: The TERM_SESSION_ID value (format: wXtYpZ:UUID)
    static func focusSession(_ termSessionId: String) {
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
        let (_, error) = AppleScriptRunner.executeScript(script)

        // Fall back to simple activation if automation permission denied
        if let error = error,
           let errorNumber = error[NSAppleScript.errorNumber] as? Int,
           errorNumber == AppleScriptRunner.automationDeniedErrorCode
        {
            logger.info("Automation permission denied for session focus, falling back to app activation")
            AppleScriptRunner.activateApp("iTerm2")
        }
    }

    // MARK: - Smart Suppression

    /// Check if notification should be suppressed because user is focused on the same session.
    /// - Parameter event: The hook event to check
    /// - Returns: true if notification should be suppressed, false otherwise
    static func shouldSuppressNotification(for event: HookEvent) -> Bool {
        // If no terminal session ID, can't suppress
        guard let termSessionId = event.termSessionId, !termSessionId.isEmpty else {
            return false
        }

        // Check if iTerm2 is frontmost app
        guard isFrontmost() else {
            return false
        }

        // Get current iTerm session via AppleScript
        guard let currentSessionId = getCurrentSessionId() else {
            return false
        }

        // FIX: Extract UUID from event's termSessionId before comparison
        // event.termSessionId is in format "wXtYpZ:UUID"
        // currentSessionId from AppleScript is just the UUID
        let eventSessionUUID = extractSessionUUID(from: termSessionId)

        // Suppress only if user is focused on the same session
        return eventSessionUUID == currentSessionId
    }

    // MARK: - App Activation

    /// Activate iTerm2 without focusing a specific session.
    /// Used when termSessionId is missing but termProgram indicates iTerm.
    static func activate() {
        guard isRunning() else {
            logger.debug("iTerm2 not running, skipping activation")
            return
        }

        AppleScriptRunner.activateApp("iTerm2")
    }

    /// Activate iTerm2, optionally focusing a specific session.
    /// - Parameter sessionId: The TERM_SESSION_ID value (format: wXtYpZ:UUID), or nil.
    static func activate(sessionId: String?) {
        if let sessionId = sessionId, !sessionId.isEmpty {
            focusSession(sessionId)
        } else {
            activate()
        }
    }

    // MARK: - Automation Permissions

    /// Check automation permission by executing AppleScript.
    /// This will show a permission dialog if not yet granted.
    /// Executes on a background queue to prevent blocking the main thread.
    /// - Parameter completion: Called on the main queue with the result
    static func requestAutomationPermission(completion: @escaping (AutomationResult) -> Void) {
        AppleScriptRunner.checkAutomationPermission(for: "iTerm", completion: completion)
    }
}
