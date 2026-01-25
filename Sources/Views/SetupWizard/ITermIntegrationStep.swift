//
//  ITermIntegrationStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// iTerm Integration step - requests automation permission for iTerm2
/// This step is only shown when iTerm2 is installed
struct ITermIntegrationStep: View {
    let onContinue: (Bool) -> Void  // Reports whether automation was configured

    @State private var isRequesting = false
    @State private var automationResult: AutomationResult?

    private var primaryButtonLabel: String {
        switch automationResult {
        case .success:
            return "Continue"
        case .denied, .error:
            return "Continue"
        case .none:
            return "Enable Automation"
        }
    }

    private var showSkipButton: Bool {
        automationResult == nil && !isRequesting
    }

    var body: some View {
        WizardStepLayout(
            title: "iTerm Integration",
            subtitle: "To focus the right terminal session when you click a notification, Your Turn needs automation access.",
            primaryButton: WizardButton(
                label: primaryButtonLabel,
                action: primaryAction,
                isDisabled: isRequesting
            ),
            skipButton: showSkipButton ? WizardButton(
                label: "Skip",
                action: { onContinue(false) }
            ) : nil,
            statusContent: { statusView },
            infoContent: { infoView }
        )
    }

    private func primaryAction() {
        if automationResult != nil {
            onContinue(automationResult == .success)
        } else {
            requestAutomation()
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if isRequesting {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Requesting permission...")
                    .foregroundStyle(.secondary)
            }
        } else if let result = automationResult {
            switch result {
            case .success:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Automation enabled")
                        .foregroundStyle(.secondary)
                }
                .font(.body)
            case .denied:
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Permission denied")
                        .foregroundStyle(.secondary)
                }
            case .error(let message):
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("Could not enable automation")
                            .foregroundStyle(.secondary)
                    }
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var infoView: some View {
        if automationResult == nil && !isRequesting {
            Text("You can enable this later in System Settings > Privacy & Security > Automation")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        } else if automationResult == .denied {
            Text("Grant access in System Settings > Privacy > Automation")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        } else {
            Color.clear
        }
    }

    private func requestAutomation() {
        isRequesting = true

        ITerm2.requestAutomationPermission { result in
            self.isRequesting = false
            self.automationResult = result
        }
    }
}

#Preview {
    ITermIntegrationStep(onContinue: { _ in })
        .frame(width: 500, height: 340)
}
