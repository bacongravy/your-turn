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
    @State private var isITermInstalled = false
    @State private var showNotificationGuidance = false

    var socketServer: SocketServer = .shared

    /// Publisher for app activation (works with programmatic NSWindow)
    private let appDidBecomeActive = NotificationCenter.default.publisher(
        for: NSApplication.didBecomeActiveNotification
    )

    var body: some View {
        Section {
//            HealthCheckRow(
//                title: "Socket Server Running",
//                subtitle: healthService.status.socket == .failed ? "Restart app to fix" : nil,
//                state: healthService.status.socket
//            )
//
            HealthCheckRow(
                title: "Claude Code Hooks",
                state: healthService.status.hooks,
                onRepairAction: healthService.repairHooks
            )

            HealthCheckRow(
                title: "Notifications",
                state: healthService.status.notifications,
                onRepairAction: { showNotificationGuidance = true },
                actionLabel: "Open Notification Settings",
                onAction: healthService.repairNotifications,
                
            )
            // Always show Terminal.app integration (built into macOS)
            HealthCheckRow(
                title: "macOS Terminal",
                state: healthService.status.terminalAppIntegration,
                onUnknownAction: healthService.checkTerminalAppIntegrationStatus,
                onRepairAction: healthService.repairTerminalAppIntegration
            )

            // Show iTerm integration if installed
            if isITermInstalled {
                HealthCheckRow(
                    title: "iTerm Integration",
                    state: healthService.status.iTermIntegration,
                    onUnknownAction: healthService.checkITermIntegrationStatus,
                    onRepairAction: healthService.repairITermIntegration
                )
            }

        }
        .onAppear {
            healthService.socketServer = socketServer
            isITermInstalled = ITerm2.isInstalled()
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
        .sheet(isPresented: $showNotificationGuidance) {
            NotificationGuidanceSheet {
                showNotificationGuidance = false
                healthService.repairNotifications()
            }
        }
    }
}

/// A single row in the health checklist
private struct HealthCheckRow: View {

    let title: String
    var subtitle: String?
    let state: CheckState
    var unknownLabel: String = "Check"
    var onUnknownAction: (() async -> Void)? = nil
    var checkingLabel: String = "Checking..."
    var repairLabel: String = "Fix"
    var onRepairAction: (() async -> Void)? = nil
    var actionLabel: String = "Configure"
    var onAction: (() async -> Void)? = nil

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
        if (state == CheckState.unknown), let onUnknownAction = onUnknownAction {
            return (unknownLabel, onUnknownAction)
        } else if state == .checking {
            return (checkingLabel, {})
        }
        if (state == CheckState.failed), let onRepairAction = onRepairAction {
            return (repairLabel, onRepairAction)
        } else if state == CheckState.ok, let onAction = onAction {
            return (actionLabel, onAction)
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
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .checking:
            Image(systemName: "ellipsis.circle")
                .foregroundStyle(.secondary)
        case .unknown:
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.secondary)
        }
    }
}
