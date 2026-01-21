//
//  AutomationStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Automation permission result
private enum AutomationResult {
    case success
    case notInstalled
    case denied
    case error(String)
}

/// Automation permission step (Step 2) - optional terminal automation
struct AutomationStep: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isRequesting = false
    @State private var automationResult: AutomationResult?

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

                if automationResult != nil {
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

        case .notInstalled:
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("iTerm2 not found")
                        .foregroundStyle(.secondary)
                }
                Text("Install iTerm2 to enable session focusing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

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

        Task {
            // Run AppleScript to trigger the automation permission dialog
            // This requires iTerm2 to be installed and will prompt for permission
            let script = NSAppleScript(source: """
                tell application "iTerm"
                    set windowCount to count of windows
                end tell
            """)

            var errorInfo: NSDictionary?
            let result = script?.executeAndReturnError(&errorInfo)

            await MainActor.run {
                isRequesting = false

                if let error = errorInfo {
                    // Check for specific error conditions
                    let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
                    let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"

                    // Error -1728: Can't get application (not installed)
                    // Error -600: Application isn't running (not installed or not found)
                    // Error -1743: User denied permission
                    if errorNumber == -1728 || errorNumber == -600 {
                        automationResult = .notInstalled
                    } else if errorNumber == -1743 {
                        automationResult = .denied
                    } else {
                        automationResult = .error(errorMessage)
                    }
                } else if result != nil {
                    // Script executed successfully
                    automationResult = .success
                } else {
                    // Script failed to execute but no error info
                    automationResult = .error("AppleScript execution failed")
                }
            }
        }
    }
}

#Preview {
    AutomationStep(onContinue: {}, onBack: {})
        .frame(width: 500, height: 350)
}
