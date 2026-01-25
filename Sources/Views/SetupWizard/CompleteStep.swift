//
//  CompleteStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Complete step - setup finished
struct CompleteStep: View {
    let onFinish: () -> Void
    let isITermInstalled: Bool
    let status: WizardStatus

    var body: some View {
        WizardStepLayout(
            title: "You're All Set!",
            subtitle: "",
            icon: .systemImage("checkmark.circle.fill", .green),
            primaryButton: WizardButton(label: "Start Using Your Turn", action: onFinish),
            infoContent: {
                summaryList
            }
        )
    }

    private var summaryList: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Hooks always succeed (can't continue without them)
            SummaryRow(enabled: true, enabledText: "Claude Code hooks installed", disabledText: "")

            // Notifications
            SummaryRow(
                enabled: status.notificationsEnabled,
                enabledText: "Notifications enabled",
                disabledText: "Notifications not enabled"
            )

            // Terminal.app (always shown - built into macOS)
            SummaryRow(
                enabled: status.terminalAppConfigured,
                enabledText: "macOS Terminal automation enabled",
                disabledText: "macOS Terminal automation not enabled"
            )

            // iTerm row only if iTerm is installed
            if isITermInstalled {
                SummaryRow(
                    enabled: status.iTermConfigured,
                    enabledText: "iTerm automation enabled",
                    disabledText: "iTerm automation not enabled"
                )
            }

            // Launch at login
            SummaryRow(
                enabled: status.launchAtLoginEnabled,
                enabledText: "Launch at login enabled",
                disabledText: "Launch at login not enabled"
            )
        }
        .padding(.horizontal, 40)
        .padding(.top, -32)
    }
}

/// Helper view for summary rows with status
private struct SummaryRow: View {
    let enabled: Bool
    let enabledText: String
    let disabledText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: enabled ? "checkmark" : "exclamationmark.triangle")
                .foregroundStyle(enabled ? .green : .orange)
                .font(.caption)
            Text(enabled ? enabledText : disabledText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("All enabled") {
    CompleteStep(
        onFinish: {},
        isITermInstalled: true,
        status: WizardStatus(notificationsEnabled: true, iTermConfigured: true, terminalAppConfigured: true, launchAtLoginEnabled: true)
    )
    .frame(width: 500, height: 340)
}

#Preview("Some disabled") {
    CompleteStep(
        onFinish: {},
        isITermInstalled: true,
        status: WizardStatus(notificationsEnabled: false, iTermConfigured: false, terminalAppConfigured: false, launchAtLoginEnabled: true)
    )
    .frame(width: 500, height: 340)
}

#Preview("No iTerm") {
    CompleteStep(
        onFinish: {},
        isITermInstalled: false,
        status: WizardStatus(notificationsEnabled: true, iTermConfigured: false, terminalAppConfigured: true, launchAtLoginEnabled: false)
    )
    .frame(width: 500, height: 340)
}
