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
        VStack(spacing: 24) {
            Spacer()

            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            // Title
            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)

            // Summary
            VStack(alignment: .leading, spacing: 8) {
                // Hooks always succeed (can't continue without them)
                SummaryRow(enabled: true, enabledText: "Claude Code hooks installed", disabledText: "")

                // Notifications
                SummaryRow(
                    enabled: status.notificationsEnabled,
                    enabledText: "Notifications enabled",
                    disabledText: "Notifications not enabled"
                )

                // iTerm row only if iTerm is installed
                if isITermInstalled {
                    SummaryRow(
                        enabled: status.iTermConfigured,
                        enabledText: "iTerm integration configured",
                        disabledText: "iTerm integration not configured"
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

            Spacer()

            // Finish button
            Button("Start Using Your Turn") {
                onFinish()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }
}

/// Helper view for summary rows with status
private struct SummaryRow: View {
    let enabled: Bool
    let enabledText: String
    let disabledText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: enabled ? "checkmark" : "xmark")
                .foregroundStyle(enabled ? .green : .red)
                .font(.caption)
            Text(enabled ? enabledText : disabledText)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("All enabled") {
    CompleteStep(
        onFinish: {},
        isITermInstalled: true,
        status: WizardStatus(notificationsEnabled: true, iTermConfigured: true, launchAtLoginEnabled: true)
    )
    .frame(width: 500, height: 340)
}

#Preview("Some disabled") {
    CompleteStep(
        onFinish: {},
        isITermInstalled: true,
        status: WizardStatus(notificationsEnabled: false, iTermConfigured: false, launchAtLoginEnabled: true)
    )
    .frame(width: 500, height: 340)
}

#Preview("No iTerm") {
    CompleteStep(
        onFinish: {},
        isITermInstalled: false,
        status: WizardStatus(notificationsEnabled: true, iTermConfigured: false, launchAtLoginEnabled: false)
    )
    .frame(width: 500, height: 340)
}
