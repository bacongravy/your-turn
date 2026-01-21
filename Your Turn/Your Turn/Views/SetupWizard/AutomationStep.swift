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
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Action area - fixed height to prevent layout shift
            VStack {
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
            }
            .frame(height: 44)

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
        }
        .padding()
    }

    private func requestAutomation() {
        isRequesting = true

        Task {
            // Launch iTerm2 first (required for automation prompt to appear)
            // Then run AppleScript to trigger the automation permission dialog
            let script = NSAppleScript(source: """
                tell application "iTerm"
                    activate
                    -- Small delay to ensure app is ready
                    delay 0.5
                    -- This triggers the automation permission prompt
                    set windowCount to count of windows
                end tell
            """)

            var errorInfo: NSDictionary?
            script?.executeAndReturnError(&errorInfo)

            // If iTerm2 isn't installed, the script fails silently
            // User can still skip this step
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
