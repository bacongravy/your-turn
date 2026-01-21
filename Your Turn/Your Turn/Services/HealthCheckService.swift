//
//  HealthCheckService.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import AppKit
import Combine
import Foundation
import os.log
import UserNotifications

/// Service that aggregates health checks for all integrations and provides repair actions.
@MainActor
class HealthCheckService: ObservableObject {
    @Published var status = HealthStatus()

    private let hookInstaller = HookInstaller()
    weak var socketServer: SocketServer?

    private let logger = Logger(subsystem: "net.bacongravy.Your-Turn", category: "HealthCheckService")

    // MARK: - Health Checks

    /// Run all health checks and update status
    func checkAll() async {
        logger.debug("Running all health checks")

        status.hooks = checkHooks()
        status.notifications = await checkNotifications()
        status.automation = checkAutomation()
        status.socket = checkSocket()

        logger.info("Health check complete: hooks=\(String(describing: self.status.hooks)), notifications=\(String(describing: self.status.notifications)), automation=\(String(describing: self.status.automation)), socket=\(String(describing: self.status.socket))")
    }

    private func checkHooks() -> CheckState {
        hookInstaller.isInstalled() ? .ok : .failed
    }

    private func checkNotifications() async -> CheckState {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .ok
        case .denied, .notDetermined:
            return .failed
        @unknown default:
            return .failed
        }
    }

    private func checkAutomation() -> CheckState {
        // Only check if iTerm2 is installed
        guard FileManager.default.fileExists(atPath: "/Applications/iTerm.app") else {
            return .ok  // Not applicable if iTerm2 not installed
        }

        let script = NSAppleScript(source: """
            tell application "iTerm" to count windows
        """)

        var errorInfo: NSDictionary?
        _ = script?.executeAndReturnError(&errorInfo)

        if let error = errorInfo {
            let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
            // -1743 = permission denied
            if errorNumber == -1743 {
                return .failed
            }
        }

        return .ok
    }

    private func checkSocket() -> CheckState {
        guard let server = socketServer else {
            return .failed
        }
        return (server.isRunning && server.error == nil) ? .ok : .failed
    }

    // MARK: - Repair Actions

    /// Repair hooks by installing them
    func repairHooks() async throws {
        logger.info("Attempting to repair hooks")

        // Check if already installed (skip if so)
        guard !hookInstaller.isInstalled() else {
            logger.debug("Hooks already installed, skipping repair")
            status.hooks = .ok
            return
        }

        try hookInstaller.installHooks()
        status.hooks = hookInstaller.isInstalled() ? .ok : .failed

        logger.info("Hooks repair complete: \(String(describing: self.status.hooks))")
    }

    /// Open notification settings in System Settings
    func repairNotifications() {
        logger.info("Opening notification settings")
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Attempt to trigger automation permission dialog, then re-check
    func repairAutomation() {
        logger.info("Attempting to repair automation permission")

        // Execute AppleScript to trigger permission dialog
        let script = NSAppleScript(source: """
            tell application "iTerm" to count windows
        """)

        var errorInfo: NSDictionary?
        _ = script?.executeAndReturnError(&errorInfo)

        // Re-check status
        status.automation = checkAutomation()

        logger.info("Automation repair complete: \(String(describing: self.status.automation))")
    }
}
