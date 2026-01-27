//
//  TerminalApp.swift
//  Your Turn
//
//  Centralized Terminal.app integration logic.
//  All Terminal.app-related functionality exposed as static functions.
//

import AppKit
import Foundation
import os.log

/// Centralized Terminal.app integration logic.
/// All Terminal.app-related functionality exposed as static functions.
enum TerminalApp {
    private static let logger = Logger(category: "TerminalApp")

    // MARK: - Constants

    static let bundleIdentifier = "com.apple.Terminal"
    static let appName = "Terminal"

    // MARK: - App State

    /// Check if Terminal.app is installed (always true on macOS)
    static func isInstalled() -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil
    }

    /// Check if Terminal.app is currently running
    static func isRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleIdentifier
        }
    }

    /// Check if Terminal.app is the frontmost application
    static func isFrontmost() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        return frontmostApp.bundleIdentifier == bundleIdentifier
    }

    // MARK: - Smart Suppression

    /// Check if notification should be suppressed because user is focused on the same terminal tab.
    /// - Parameter event: The hook event to check
    /// - Returns: true if notification should be suppressed, false otherwise
    static func shouldSuppressNotification(for event: HookEvent) -> Bool {
        // If no tty, can't suppress
        guard let tty = event.tty, !tty.isEmpty else {
            return false
        }

        // Check if Terminal.app is frontmost app
        guard isFrontmost() else {
            return false
        }

        // Get current Terminal tab's tty via AppleScript
        guard let currentTty = getCurrentTty() else {
            return false
        }

        // Suppress only if user is focused on the same tab
        return tty == currentTty
    }

    /// Get the tty of the currently selected Terminal.app tab via AppleScript
    static func getCurrentTty() -> String? {
        let script = """
            tell application "Terminal"
                return tty of selected tab of front window
            end tell
            """

        let (result, error) = AppleScriptRunner.executeScript(script)

        if error != nil {
            // Terminal not running, no window, or other error - fail gracefully
            return nil
        }

        return result?.stringValue
    }

    // MARK: - App Activation

    /// Activate Terminal.app without focusing a specific tab.
    /// Used when tty is missing but termProgram indicates Terminal.
    static func activate() {
        guard isRunning() else { return }
        AppleScriptRunner.activateApp("Terminal")
    }

    /// Activate Terminal.app, optionally focusing a specific tab by tty.
    /// - Parameter tty: The tty path (e.g., "/dev/ttys001"), or nil.
    static func activate(tty: String?) {
        if let tty = tty, !tty.isEmpty {
            focusTab(tty: tty)
        } else {
            activate()
        }
    }

    /// Focus a specific Terminal.app tab by its tty.
    /// Falls back to activating Terminal.app without tab focus if tab not found.
    /// Falls back to simple activation if automation permission is denied.
    /// - Parameter tty: The tty path (e.g., "/dev/ttys001")
    static func focusTab(tty: String) {
        guard isRunning() else { return }

        // AppleScript iterates all windows/tabs to find match by tty
        let script = """
            tell application "Terminal"
                repeat with w in windows
                    repeat with t in tabs of w
                        if tty of t is "\(tty)" then
                            set selected tab of w to t
                            set frontmost of w to true
                            activate
                            return true
                        end if
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
            logger.info("Automation permission denied for tab focus, falling back to app activation")
            AppleScriptRunner.activateApp("Terminal")
        }
    }

    // MARK: - Automation Permissions

    /// Check automation permission by executing AppleScript.
    /// This will show a permission dialog if not yet granted.
    /// Executes on a background queue to prevent blocking the main thread.
    /// - Parameter completion: Called on the main queue with the result
    static func requestAutomationPermission(completion: @escaping (AutomationResult) -> Void) {
        AppleScriptRunner.checkAutomationPermission(for: "Terminal", completion: completion)
    }
}
