//
//  WelcomeStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Welcome step (Step 0) - introduces the app
struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
            }

            // Title
            Text("Welcome to Your Turn")
                .font(.title)
                .fontWeight(.bold)

            // Description
            Text("Get notified when Claude Code needs your attention, and jump to the right terminal with one click.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)

            Spacer()

            // Continue button
            Button("Continue") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    WelcomeStep(onContinue: {})
        .frame(width: 500, height: 350)
}
