//
//  AutomationStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Automation permission step (Step 2) - optional terminal automation
struct AutomationStep: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isRequesting = false
    @State private var hasRequested = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Title
            Text("Terminal Automation (Optional)")
                .font(.title)
                .fontWeight(.bold)

            // Explanation
            Text("To focus the right terminal session when you click a notification, Your Turn needs automation access.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Note
            Text("You can enable this later in System Settings > Privacy & Security > Automation")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Action area
            if hasRequested {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Permission requested")
                        .foregroundStyle(.secondary)
                }
                .font(.body)
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
            }

            Spacer()

            // Navigation
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)

                Spacer()

                if hasRequested {
                    Button("Continue") {
                        onContinue()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Skip") {
                        onContinue()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
                .frame(height: 20)
        }
        .padding()
    }

    private func requestAutomation() {
        isRequesting = true

        // Run AppleScript to trigger automation permission prompt for iTerm2
        Task {
            // This will trigger the automation permission dialog
            let script = NSAppleScript(source: """
                tell application id "com.googlecode.iterm2"
                    name
                end tell
            """)

            var errorInfo: NSDictionary?
            script?.executeAndReturnError(&errorInfo)

            // We don't care about the result - just triggering the permission prompt
            await MainActor.run {
                isRequesting = false
                hasRequested = true
            }
        }
    }
}

#Preview {
    AutomationStep(onContinue: {}, onBack: {})
        .frame(width: 500, height: 350)
}
