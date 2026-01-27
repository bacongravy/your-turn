//
//  Warp.swift
//  Your Turn
//
//  Centralized Warp terminal integration logic.
//  All Warp-related functionality exposed as static functions.
//

import AppKit
import Foundation

/// Centralized Warp terminal integration logic.
/// All Warp-related functionality exposed as static functions.
enum Warp {
    // MARK: - Constants

    /// Warp has two variants: Stable and Preview
    static let bundleIdentifiers = ["dev.warp.Warp-Stable", "dev.warp.Warp-Preview"]
    static let appName = "Warp"

    // MARK: - App State

    /// Check if Warp is currently running (either Stable or Preview)
    static func isRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            bundleIdentifiers.contains(where: { $0 == app.bundleIdentifier })
        }
    }

    // MARK: - App Activation

    /// Activate Warp (bring to front).
    /// Warp does not support AppleScript for session-level focus.
    static func activate() {
        guard isRunning() else { return }
        AppleScriptRunner.activateApp(appName)
    }
}
