//
//  HealthStatusSection.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Displays health status checklist with per-item Fix buttons
struct HealthStatusSection: View {
    @StateObject private var healthService = HealthCheckService()
    @AppStorage("setupComplete") private var setupComplete = true

    var socketServer: SocketServer?

    /// Publisher for app activation (works with programmatic NSWindow)
    private let appDidBecomeActive = NotificationCenter.default.publisher(
        for: NSApplication.didBecomeActiveNotification
    )

    var body: some View {
        Section {
            HealthCheckRow(
                title: "Socket Server Running",
                subtitle: healthService.status.socket == .failed ? "Restart app to fix" : nil,
                state: healthService.status.socket,
                onAction: nil  // No repair possible, app restart needed
            )

            HealthCheckRow(
                title: "Hooks Installed",
                state: healthService.status.hooks,
                onAction: repairHooks
            )

            HealthCheckRow(
                title: "Notifications Permitted",
                state: healthService.status.notifications,
                onAction: repairNotifications
            )

            HealthCheckRow(
                title: "iTerm Integration",
                state: healthService.status.automation,
                actionLabel: healthService.status.automation == .unknown ? "Check" : "Fix",
                onAction: healthService.status.automation == .unknown ? checkAutomation : fixAutomation
            )

        } header: {
            Text("Integration Status")
        }
        .onAppear {
            // Use provided socketServer or fall back to shared instance
            healthService.socketServer = socketServer ?? SocketServer.shared
            Task {
                await healthService.checkAll()
            }
        }
        .onReceive(appDidBecomeActive) { _ in
            // Re-check when returning from System Settings
            Task {
                await healthService.checkAll()
            }
        }
    }

    // MARK: - Repair Wrappers

    private func repairHooks() async {
        do {
            try await healthService.repairHooks()
        } catch {
            // Silent failure - status shows result
        }
    }

    private func repairNotifications() async {
        healthService.repairNotifications()
    }

    private func checkAutomation() async {
        // Just check, don't open settings
        healthService.testAutomation(openSettingsOnFailure: false)
    }

    private func fixAutomation() async {
        // Re-check and open settings if still failed
        healthService.testAutomation(openSettingsOnFailure: true)
    }
}

/// A single row in the health checklist
private struct HealthCheckRow: View {
    let title: String
    var subtitle: String?
    let state: CheckState
    var actionLabel: String = "Fix"
    let onAction: (() async -> Void)?
    var okActionLabel: String? = nil
    var onOkAction: (() async -> Void)? = nil

    @State private var isActing = false

    var body: some View {
        HStack {
            // Status icon
            statusIcon
                .frame(width: 20)

            // Title and subtitle
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Action button - show for failed/unknown with onAction, or ok with onOkAction
            if let (label, action) = currentAction {
                Button(label) {
                    Task {
                        isActing = true
                        await action()
                        isActing = false
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isActing)
            }
        }
    }

    /// Returns the appropriate button label and action based on current state
    private var currentAction: (String, () async -> Void)? {
        if (state == .failed || state == .unknown), let onAction = onAction {
            return (actionLabel, onAction)
        } else if state == .ok, let okLabel = okActionLabel, let okAction = onOkAction {
            return (okLabel, okAction)
        }
        return nil
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .ok:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .checking:
            Image(systemName: "circle.dotted")
                .foregroundStyle(.secondary)
        case .unknown:
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.secondary)
        }
    }
}
