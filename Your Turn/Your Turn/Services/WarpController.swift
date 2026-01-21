//
//  WarpController.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import AppKit
import Foundation
import os.log

/// Controller for Warp terminal activation.
/// Warp does not support AppleScript, so we use NSWorkspace activation.
@MainActor
final class WarpController: TerminalActivating {
    static let shared = WarpController()
    private let logger = Logger(subsystem: "net.bacongravy.Your-Turn", category: "WarpController")
    private let bundleIds = ["dev.warp.Warp-Stable", "dev.warp.Warp-Preview"]

    private init() {}

    func isRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            bundleIds.contains(where: { $0 == app.bundleIdentifier })
        }
    }

    /// Activate Warp.
    /// - Parameter sessionId: Ignored. Warp does not support session-level focus.
    func activate(sessionId: String?) {
        guard let warpApp = findRunningWarp() else {
            logger.debug("Warp not running, skipping activation")
            return
        }

        warpApp.activate(options: [.activateAllWindows])
    }

    private func findRunningWarp() -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { app in
            bundleIds.contains(where: { $0 == app.bundleIdentifier })
        }
    }
}
