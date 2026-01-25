//
//  SetupWizardView.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Identifies each wizard step
enum WizardStep {
    case welcome
    case hooks
    case notifications
    case terminalApp
    case iTerm
    case launchAtLogin
    case complete
}

/// Tracks the completion status of each wizard step
struct WizardStatus {
    var notificationsEnabled: Bool = false
    var iTermConfigured: Bool = false
    var terminalAppConfigured: Bool = false
    var launchAtLoginEnabled: Bool = false
}

/// Container view for the setup wizard
/// Step order: Welcome -> Hooks -> Notifications -> Terminal.app -> iTerm (if installed) -> Launch at Login -> Complete
struct SetupWizardView: View {
    @State private var currentStep = 0
    @State private var isITermInstalled = false
    @State private var status = WizardStatus()
    let onComplete: () -> Void

    /// Build steps array dynamically - skipped steps just aren't added
    private var steps: [WizardStep] {
        var result: [WizardStep] = [.welcome, .hooks, .notifications, .terminalApp]
        if isITermInstalled {
            result.append(.iTerm)
        }
        result.append(contentsOf: [.launchAtLogin, .complete])
        return result
    }

    /// Number of visible steps
    private var totalSteps: Int {
        steps.count
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
                        .fill(index <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .frame(height: 60)
        }
        .frame(width: 500, height: 400)
        .onAppear {
            isITermInstalled = ITerm2.isInstalled()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSetup)) { _ in
            // Reset to first step when wizard is opened (including re-run)
            currentStep = 0
            status = WizardStatus()
            isITermInstalled = ITerm2.isInstalled()
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch steps[currentStep] {
        case .welcome:
            WelcomeStep(onContinue: nextStep)
        case .hooks:
            HooksStep(onContinue: nextStep)
        case .notifications:
            NotificationsStep(
                onContinue: { enabled in
                    status.notificationsEnabled = enabled
                    nextStep()
                }
            )
        case .terminalApp:
            TerminalAppIntegrationStep(
                onContinue: { configured in
                    status.terminalAppConfigured = configured
                    nextStep()
                }
            )
        case .iTerm:
            ITermIntegrationStep(
                onContinue: { configured in
                    status.iTermConfigured = configured
                    nextStep()
                }
            )
        case .launchAtLogin:
            LaunchAtLoginStep(
                onContinue: { enabled in
                    status.launchAtLoginEnabled = enabled
                    nextStep()
                }
            )
        case .complete:
            CompleteStep(
                onFinish: onComplete,
                isITermInstalled: isITermInstalled,
                status: status
            )
        }
    }

    private func nextStep() {
        if currentStep < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentStep += 1
            }
        }
    }
}

#Preview("With iTerm") {
    SetupWizardView(onComplete: {})
}

#Preview("Without iTerm") {
    SetupWizardView(onComplete: {})
}
