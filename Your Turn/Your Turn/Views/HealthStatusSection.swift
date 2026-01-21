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

    var socketServer: SocketServer?

    var body: some View {
        Section {
            HealthCheckRow(
                title: "Hooks Installed",
                state: healthService.status.hooks,
                onFix: repairHooks
            )

            HealthCheckRow(
                title: "Notifications Permitted",
                state: healthService.status.notifications,
                onFix: repairNotifications
            )

            HealthCheckRow(
                title: "Automation Permission",
                subtitle: "Optional - enables session focusing",
                state: healthService.status.automation,
                onFix: repairAutomation
            )

            HealthCheckRow(
                title: "Socket Server Running",
                subtitle: healthService.status.socket == .failed ? "Restart app to fix" : nil,
                state: healthService.status.socket,
                onFix: nil  // No repair possible, app restart needed
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

    private func repairAutomation() async {
        healthService.repairAutomation()
    }
}

/// A single row in the health checklist
private struct HealthCheckRow: View {
    let title: String
    var subtitle: String?
    let state: CheckState
    let onFix: (() async -> Void)?

    @State private var isFixing = false

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

            // Fix button - only show if failed and fixable
            if state == .failed, let onFix = onFix {
                Button("Fix") {
                    Task {
                        isFixing = true
                        await onFix()
                        isFixing = false
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isFixing)
            }
        }
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
        }
    }
}
