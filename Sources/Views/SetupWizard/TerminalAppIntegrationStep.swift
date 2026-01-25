//
//  TerminalAppIntegrationStep.swift
//  Your Turn
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

/// Terminal.app Integration step - requests automation permission for Terminal.app
struct TerminalAppIntegrationStep: View {
    let onContinue: (Bool) -> Void  // Reports whether automation was configured

    @State private var isRequesting = false
    @State private var automationResult: AutomationResult?
    @State private var showGuidanceSheet = false

    private let appDidBecomeActive = NotificationCenter.default.publisher(
        for: NSApplication.didBecomeActiveNotification
    )

    private var primaryButtonLabel: String {
        switch automationResult {
        case .success:
            return "Continue"
        case .denied, .error:
            return "Open Automation Settings"
        case .none:
            return "Enable Automation"
        }
    }

    private var showSkipButton: Bool {
        switch automationResult {
        case .none:
            return !isRequesting
        case .denied, .error:
            return true
        case .success:
            return false
        }
    }

    var body: some View {
        WizardStepLayout(
            title: "macOS Terminal",
            subtitle: "To focus the right terminal tab when you click a notification, Your Turn needs automation access.",
            primaryButton: WizardButton(
                label: primaryButtonLabel,
                action: primaryAction,
                isDisabled: isRequesting
            ),
            skipButton: showSkipButton ? WizardButton(
                label: "Skip",
                action: { onContinue(false) }
            ) : nil,
            statusContent: { statusView },
            infoContent: { infoView }
        )
        .onReceive(appDidBecomeActive) { _ in
            checkCurrentStatus()
        }
        .sheet(isPresented: $showGuidanceSheet) {
            AutomationGuidanceSheet(terminalAppName: "Terminal") {
                showGuidanceSheet = false
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func primaryAction() {
        switch automationResult {
        case .success:
            onContinue(true)
        case .denied, .error:
            showGuidanceSheet = true
        case .none:
            requestAutomation()
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if isRequesting {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Requesting permission...")
                    .foregroundStyle(.secondary)
            }
        } else if let result = automationResult {
            switch result {
            case .success:
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Automation is enabled")
                        .foregroundStyle(.secondary)
                }
                .font(.body)
            case .denied, .error:
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Automation is disabled")
                }
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Automation is not enabled")
            }
        }
    }

    @ViewBuilder
    private var infoView: some View {
        if let result = automationResult, result.isError {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.forward.app")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text("Your Turn will still activate the app when Claude Code needs attention.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        } else {
            Color.clear
        }
    }

    private func checkCurrentStatus() {
        // Only re-check if previously denied or error
        guard let result = automationResult, result.isError else { return }

        TerminalApp.requestAutomationPermission { newResult in
            self.automationResult = newResult
        }
    }

    private func requestAutomation() {
        isRequesting = true

        TerminalApp.requestAutomationPermission { result in
            self.isRequesting = false
            self.automationResult = result
        }
    }
}

#Preview {
    TerminalAppIntegrationStep(onContinue: { _ in })
        .frame(width: 500, height: 340)
}
