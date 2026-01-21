//
//  LaunchAtLoginStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI
import ServiceManagement

/// Launch at Login step (Step 4) - opt-in to auto-start
struct LaunchAtLoginStep: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var enableLaunchAtLogin = true  // Default ON per CONTEXT.md

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Title
            Text("Launch at Login")
                .font(.title)
                .fontWeight(.bold)

            // Explanation
            Text("Would you like Your Turn to start automatically when you log in?")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Benefit text
            Text("This ensures you never miss a Claude notification.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Toggle
            Toggle("Launch at Login", isOn: $enableLaunchAtLogin)
                .toggleStyle(.switch)
                .padding(.horizontal, 60)

            Spacer()

            // Navigation
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Continue") {
                    applyChoice()
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    private func applyChoice() {
        if enableLaunchAtLogin {
            // Register with SMAppService, silent failure
            try? SMAppService.mainApp.register()
        }
        // If disabled, do nothing (don't unregister - user hasn't enabled it yet)
    }
}

#Preview {
    LaunchAtLoginStep(onContinue: {}, onBack: {})
        .frame(width: 500, height: 350)
}
