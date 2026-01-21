//
//  SetupWizardView.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Container view for the 5-step setup wizard
struct SetupWizardView: View {
    @State private var currentStep = 0
    let totalSteps = 5
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Step content - fixed height so dots stay in place
            Group {
                switch currentStep {
                case 0:
                    WelcomeStep(onContinue: nextStep)
                case 1:
                    HooksStep(onContinue: nextStep, onBack: prevStep)
                case 2:
                    AutomationStep(onContinue: nextStep, onBack: prevStep)
                case 3:
                    NotificationsStep(onContinue: nextStep, onBack: prevStep)
                case 4:
                    CompleteStep(onFinish: onComplete)
                default:
                    EmptyView()
                }
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
        .onReceive(NotificationCenter.default.publisher(for: .openSetup)) { _ in
            // Reset to first step when wizard is opened (including re-run)
            currentStep = 0
        }
    }

    private func nextStep() {
        if currentStep < totalSteps - 1 {
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
}

#Preview {
    SetupWizardView(onComplete: {})
}
