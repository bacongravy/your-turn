//
//  HooksStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Hooks installation step - installs Claude Code hooks
struct HooksStep: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isInstalling = false
    @State private var isInstalled = false
    @State private var installError: String?

    private let hookInstaller = HookInstaller()

    var body: some View {
        WizardStepLayout(
            title: "Install Claude Code Hooks",
            subtitle: "Your Turn needs to install a hook that tells it when Claude stops working.",
            onBack: onBack,
            onContinue: onContinue,
            continueDisabled: !isInstalled
        ) {
            VStack(spacing: 12) {
                if isInstalled {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Hooks installed successfully")
                            .foregroundStyle(.secondary)
                    }
                    .font(.body)
                } else if let error = installError {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("Installation failed")
                        }
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Retry") {
                        installHooks()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInstalling)
                } else {
                    Button {
                        installHooks()
                    } label: {
                        if isInstalling {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal, 8)
                        } else {
                            Text("Install Hooks")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isInstalling)

                    // Info text below button - hidden when installed
                    VStack(spacing: 4) {
                        Text("Adds hooks to ~/.claude/settings.json")
                        Text("Installs a script to ~/.claude/hooks/")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                }
            }
        }
        .onAppear {
            if hookInstaller.isInstalled() {
                isInstalled = true
            }
        }
    }

    private func installHooks() {
        isInstalling = true
        installError = nil

        Task {
            do {
                try hookInstaller.installHooks()
                await MainActor.run {
                    isInstalling = false
                    isInstalled = true
                }
            } catch {
                await MainActor.run {
                    isInstalling = false
                    installError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    HooksStep(onContinue: {}, onBack: {})
        .frame(width: 500, height: 340)
}
