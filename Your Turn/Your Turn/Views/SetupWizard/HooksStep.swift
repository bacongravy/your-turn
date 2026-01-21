//
//  HooksStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI

/// Hooks installation step (Step 1) - installs Claude Code hooks
struct HooksStep: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isInstalling = false
    @State private var isInstalled = false
    @State private var installError: String?
    @State private var showDetails = false

    private let hookInstaller = HookInstaller()

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Title
            Text("Install Claude Code Hooks")
                .font(.title)
                .fontWeight(.bold)

            // Explanation
            Text("Your Turn needs to install a hook that tells it when Claude stops working.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)

            // Disclosure for details - anchored at top so it expands downward only
            VStack(alignment: .leading) {
                DisclosureGroup("What this does", isExpanded: $showDetails) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Creates config in ~/.claude/settings.json")
                        Text("Deploys a script to ~/.claude/hooks/")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 60)
            .frame(height: 80, alignment: .top)

            Spacer()

            // Status/action area - fixed height to prevent layout shift
            VStack(spacing: 12) {
                if isInstalled {
                    // Success state
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Hooks installed successfully")
                            .foregroundStyle(.secondary)
                    }
                    .font(.body)
                } else if let error = installError {
                    // Error state
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
                    // Initial state
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
                }
            }
            .frame(height: 60)

            Spacer()

            // Navigation - always show both buttons
            HStack {
                Button("Back") {
                    onBack()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isInstalled)
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .onAppear {
            // Check if already installed
            if hookInstaller.isInstalled() {
                isInstalled = true
            }
        }
    }

    private func installHooks() {
        isInstalling = true
        installError = nil

        // Run installation on background thread
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
        .frame(width: 500, height: 350)
}
