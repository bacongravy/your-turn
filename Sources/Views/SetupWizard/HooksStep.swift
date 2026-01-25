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

    @State private var isInstalling = false
    @State private var isInstalled = false
    @State private var installError: String?

    private let hookInstaller = HookInstaller()

    private var primaryButtonLabel: String {
        if isInstalled {
            return "Continue"
        } else if installError != nil {
            return "Retry"
        } else {
            return "Install Hooks"
        }
    }

    private var primaryButtonAction: () -> Void {
        if isInstalled {
            return onContinue
        } else {
            return installHooks
        }
    }

    var body: some View {
        WizardStepLayout(
            title: "Install Claude Code Hooks",
            subtitle: "Your Turn uses hooks to know when Claude\u{00A0}Code is waiting for input or has finished a task.",
            primaryButton: WizardButton(
                label: primaryButtonLabel,
                action: primaryButtonAction,
                isDisabled: isInstalling
            ),
            statusContent: { statusView },
            infoContent: { infoView }
        )
        .onAppear {
            if hookInstaller.isInstalled() {
                isInstalled = true
            }
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if isInstalling {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Installing hooks...")
                    .foregroundStyle(.secondary)
            }
        } else if isInstalled {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Hooks are installed")
                    .foregroundStyle(.secondary)
            }
            .font(.body)
        } else if let error = installError {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("Hooks could not be installed")
                }
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Hooks are not installed")
            }
        }
    }

    @ViewBuilder
    private var infoView: some View {
        Color.clear
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
    HooksStep(onContinue: {})
        .frame(width: 500, height: 340)
}
