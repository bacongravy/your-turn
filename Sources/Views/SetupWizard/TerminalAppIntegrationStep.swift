//
//  TerminalAppIntegrationStep.swift
//  Your Turn
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

/// Terminal.app Integration step - requests automation permission for Terminal.app
/// This step is only shown when Terminal.app is detected as the user's terminal
struct TerminalAppIntegrationStep: View {
    let onContinue: (Bool) -> Void  // Reports whether automation was configured
    let onBack: () -> Void

    @State private var isRequesting = false
    @State private var automationResult: AutomationResult?

    var body: some View {
        WizardStepLayout(
            title: "macOS Terminal",
            subtitle: "To focus the right terminal tab when you click a notification, Your Turn needs automation access.",
            onBack: onBack,
            onContinue: { onContinue(automationResult == .success) },
            continueLabel: continueButtonLabel
        ) {
            VStack(spacing: 12) {
                if let result = automationResult {
                    resultView(for: result)
                } else {
                    Button {
                        requestAutomation()
                    } label: {
                        if isRequesting {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal, 8)
                        } else {
                            Text("Enable Automation")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isRequesting)

                    Text("You can enable this later in System Settings > Privacy & Security > Automation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
        }
    }

    private var continueButtonLabel: String {
        switch automationResult {
        case .success:
            return "Continue"
        case .denied, .error, .none:
            return "Skip"
        }
    }

    @ViewBuilder
    private func resultView(for result: AutomationResult) -> some View {
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
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Permission denied")
                        .foregroundStyle(.secondary)
                }
                Text("Grant access in System Settings > Privacy > Automation")
                    .font(.caption)
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
    }

    private func requestAutomation() {
        isRequesting = true

        TerminalApp.requestAutomationPermission { result in
            self.isRequesting = false
            self.automationResult = result
        }
    }
}

#Preview {
    TerminalAppIntegrationStep(onContinue: { _ in }, onBack: {})
        .frame(width: 500, height: 340)
}
