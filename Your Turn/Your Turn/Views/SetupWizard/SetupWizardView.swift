//
//  SetupWizardView.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Tracks the completion status of each wizard step
struct WizardStatus {
    var notificationsEnabled: Bool = false
    var iTermConfigured: Bool = false
    var launchAtLoginEnabled: Bool = false
}

/// Container view for the setup wizard
/// Step order: Welcome -> Hooks -> Notifications -> iTerm Integration (if installed) -> Launch at Login -> Complete
struct SetupWizardView: View {
    @State private var currentStep = 0
    @State private var isITermInstalled = false
    @State private var status = WizardStatus()
    let onComplete: () -> Void

    /// Number of visible steps (varies based on iTerm installation)
    private var totalSteps: Int {
        isITermInstalled ? 6 : 5
    }

    var body: some View {
        VStack(spacing: 0) {
            // Step content - fixed height so dots stay in place
            Group {
                stepView
            }
            .frame(maxWidth: .infinity)
            .frame(height: 340)

            // Progress dots - always at fixed position
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index <= displayStepIndex ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(height: 60)
        }
        .frame(width: 500, height: 400)
        .onAppear {
            checkITermInstalled()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSetup)) { _ in
            // Reset to first step when wizard is opened (including re-run)
            currentStep = 0
            status = WizardStatus()
            checkITermInstalled()
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch currentStep {
        case 0:
            WelcomeStep(onContinue: nextStep)
        case 1:
            HooksStep(onContinue: nextStep, onBack: prevStep)
        case 2:
            NotificationsStep(
                onContinue: { enabled in
                    status.notificationsEnabled = enabled
                    nextStep()
                },
                onBack: prevStep
            )
        case 3:
            if isITermInstalled {
                ITermIntegrationStep(
                    onContinue: { configured in
                        status.iTermConfigured = configured
                        nextStep()
                    },
                    onBack: prevStep
                )
            } else {
                LaunchAtLoginStep(
                    onContinue: { enabled in
                        status.launchAtLoginEnabled = enabled
                        nextStep()
                    },
                    onBack: prevStep
                )
            }
        case 4:
            if isITermInstalled {
                LaunchAtLoginStep(
                    onContinue: { enabled in
                        status.launchAtLoginEnabled = enabled
                        nextStep()
                    },
                    onBack: prevStep
                )
            } else {
                CompleteStep(
                    onFinish: onComplete,
                    isITermInstalled: false,
                    status: status
                )
            }
        case 5:
            CompleteStep(
                onFinish: onComplete,
                isITermInstalled: isITermInstalled,
                status: status
            )
        default:
            EmptyView()
        }
    }

    /// Display index for progress dots (accounts for iTerm step)
    private var displayStepIndex: Int {
        currentStep
    }

    private func nextStep() {
        let maxStep = isITermInstalled ? 5 : 4
        if currentStep < maxStep {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentStep += 1
            }
        }
    }

    private func prevStep() {
        if currentStep > 0 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentStep -= 1
            }
        }
    }

    private func checkITermInstalled() {
        let iTermPaths = [
            "/Applications/iTerm.app",
            NSHomeDirectory() + "/Applications/iTerm.app"
        ]
        isITermInstalled = iTermPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }
}

#Preview("With iTerm") {
    SetupWizardView(onComplete: {})
}

#Preview("Without iTerm") {
    SetupWizardView(onComplete: {})
}
