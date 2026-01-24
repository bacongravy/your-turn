//
//  LaunchAtLoginStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI
import ServiceManagement

/// Launch at Login step - opt-in to auto-start
struct LaunchAtLoginStep: View {
    let onContinue: (Bool) -> Void  // Reports whether launch at login was enabled
    let onBack: () -> Void

    @State private var enableLaunchAtLogin = true  // Default ON

    var body: some View {
        WizardStepLayout(
            title: "Launch at Login",
            subtitle: "Would you like Your Turn to start automatically when you log in?",
            onBack: onBack,
            onContinue: {
                applyChoice()
                onContinue(enableLaunchAtLogin)
            }
        ) {
            VStack(spacing: 12) {
                Toggle("Launch at Login", isOn: $enableLaunchAtLogin)
                    .toggleStyle(.switch)

                Text("This ensures you never miss a Claude notification.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
        }
    }

    private func applyChoice() {
        if enableLaunchAtLogin {
            try? SMAppService.mainApp.register()
        }
    }
}

#Preview {
    LaunchAtLoginStep(onContinue: { _ in }, onBack: {})
        .frame(width: 500, height: 340)
}
