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
    static let shared = HealthCheckService()

    @Published var status = HealthStatus()

    private let hookInstaller = HookInstaller()
    var socketServer: SocketServer = .shared

    private let logger = Logger(category: "HealthCheckService")

    // MARK: - Health Checks

    /// Run all health checks and update status
    /// Note: Automation is NOT checked automatically (triggers permission dialog)
    func checkAll() async {
        logger.debug("Running all health checks")

        status.socket = checkSocket()
        status.hooks = checkHooks()
        status.notifications = await checkNotifications()
        // Don't check automation if in .unknown state - it triggers a permission dialog
        // User must explicitly click "Check" to trigger the first check
        // Once checked (ok or failed), re-check on subsequent checkAll() calls
        // since the permission dialog won't appear again
        if status.iTermIntegration == .ok || status.iTermIntegration == .failed {
            await checkITermIntegrationStatus()
        }
        if status.terminalAppIntegration == .ok || status.terminalAppIntegration == .failed {
            await checkTerminalAppIntegrationStatus()
        }

        logger.info("Health check complete: socket=\(String(describing: self.status.socket)), hooks=\(String(describing: self.status.hooks)), notifications=\(String(describing: self.status.notifications)), iTerm=\(String(describing: self.status.iTermIntegration)), terminal=\(String(describing: self.status.terminalAppIntegration))")
    }

    private func checkSocket() -> CheckState {
        return (socketServer.isRunning && socketServer.error == nil) ? .ok : .failed
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

    /// Check automation permission by triggering AppleScript
    /// WARNING: This will show a permission dialog if not yet granted!
    /// Only call this when user explicitly requests it (e.g., clicking "Check" button)
    func checkITermIntegrationStatus() async {
        logger.info("Checking iTerm integration status")
        status.iTermIntegration = .checking

        await withCheckedContinuation { continuation in
            ITerm2.requestAutomationPermission { @MainActor result in
                switch result {
                case .success:
                    self.status.iTermIntegration = .ok
                case .denied, .error:
                    self.status.iTermIntegration = .failed
                }

                self.logger.info("iTerm integration check complete: \(String(describing: self.status.iTermIntegration))")
                continuation.resume()
            }
        }
    }

    /// Check Terminal.app automation permission by triggering AppleScript
    /// WARNING: This will show a permission dialog if not yet granted!
    /// Only call this when user explicitly requests it (e.g., clicking "Check" button)
    func checkTerminalAppIntegrationStatus() async {
        logger.info("Checking Terminal.app integration status")
        status.terminalAppIntegration = .checking

        await withCheckedContinuation { continuation in
            TerminalApp.requestAutomationPermission { @MainActor result in
                switch result {
                case .success:
                    self.status.terminalAppIntegration = .ok
                case .denied, .error:
                    self.status.terminalAppIntegration = .failed
                }

                self.logger.info("Terminal.app integration check complete: \(String(describing: self.status.terminalAppIntegration))")
                continuation.resume()
            }
        }
    }

    // MARK: - Repair Actions

    /// Repair hooks by installing them
    func repairHooks() async {
        logger.info("Attempting to repair hooks")

        // Check if already installed (skip if so)
        guard !hookInstaller.isInstalled() else {
            logger.info("Hooks already installed, skipping repair")
            status.hooks = .ok
            return
        }

        do {
            try hookInstaller.installHooks()
            status.hooks = .ok
        } catch {
            logger.error("Hook repair failed: \(error.localizedDescription)")
            status.hooks = .failed
        }

        logger.info("Hooks repair complete: \(String(describing: self.status.hooks))")
    }

    /// Open notification settings in System Settings
    func repairNotifications() {
        logger.info("Opening notification settings")
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func repairITermIntegration() async {
        logger.info("Attempting to repair iTerm integration")
        await checkITermIntegrationStatus()

        if self.status.iTermIntegration == .failed {
            self.logger.info("Opening privacy automation settings (manual repair required)")
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }
        }
        else {
            self.logger.info("iTerm integration already set up, skipping repair")
        }
    }

    func repairTerminalAppIntegration() async {
        logger.info("Attempting to repair Terminal.app integration")
        await checkTerminalAppIntegrationStatus()

        if self.status.terminalAppIntegration == .failed {
            self.logger.info("Opening privacy automation settings (manual repair required)")
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }
        }
        else {
            self.logger.info("Terminal.app integration already set up, skipping repair")
        }
    }

}
