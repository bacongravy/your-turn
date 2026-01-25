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

    @State private var enableLaunchAtLogin = true  // Default ON

    var body: some View {
        WizardStepLayout(
            title: "Enable Launch at Login",
            subtitle: "Automatically start Your Turn when you log in to ensure you never miss a Claude\u{00A0}Code notification.",
            primaryButton: WizardButton(
                label: "Continue",
                action: {
                    applyChoice()
                    onContinue(enableLaunchAtLogin)
                }
            ),
            infoContent: {
                VStack(spacing: 12) {
                    Toggle("Launch at Login", isOn: $enableLaunchAtLogin)
                        .toggleStyle(.switch)
                }
                .padding(.horizontal, 40)
            }
        )
    }

    private func applyChoice() {
        if enableLaunchAtLogin {
            try? SMAppService.mainApp.register()
        }
    }
}

#Preview {
    LaunchAtLoginStep(onContinue: { _ in })
        .frame(width: 500, height: 340)
}
