//
//  NotificationsStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI
import UserNotifications

/// Notifications permission step - request notification access
struct NotificationsStep: View {
    let onContinue: (Bool) -> Void  // Reports whether notifications were enabled

    @State private var isRequesting = false
    @State private var authorizationStatus: UNAuthorizationStatus?
    @State private var showDeniedMessage = false
    @State private var showGuidanceSheet = false

    private let appDidBecomeActive = NotificationCenter.default.publisher(
        for: NSApplication.didBecomeActiveNotification
    )

    private var primaryButtonLabel: String {
        if authorizationStatus == .authorized {
            return "Continue"
        } else if showDeniedMessage {
            return "Open Notification Settings"
        } else {
            return "Enable Notifications"
        }
    }

    private var showSkipButton: Bool {
        showDeniedMessage
    }

    var body: some View {
        WizardStepLayout(
            title: "Enable Notifications",
            subtitle: "Your Turn uses macOS notifications to alert you when Claude needs your attention.",
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
        .onAppear {
            checkCurrentStatus()
        }
        .onReceive(appDidBecomeActive) { _ in
            checkCurrentStatus()
        }
        .sheet(isPresented: $showGuidanceSheet) {
            NotificationGuidanceSheet {
                showGuidanceSheet = false
                if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func primaryAction() {
        if authorizationStatus == .authorized {
            onContinue(true)
        } else if showDeniedMessage {
            showGuidanceSheet = true
        } else {
            requestNotifications()
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
        } else if authorizationStatus == .authorized {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Notifications enabled")
                    .foregroundStyle(.secondary)
            }
            .font(.body)
        } else if showDeniedMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Notifications are disabled")
            }
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var infoView: some View {
        if showDeniedMessage {
            // Audio fallback message
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text("Your Turn will still generate audio alerts when Claude needs attention.")
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
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
                self.showDeniedMessage = settings.authorizationStatus == .denied
            }
        }
    }

    private func requestNotifications() {
        isRequesting = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { @MainActor in
                self.isRequesting = false
                if granted {
                    self.authorizationStatus = .authorized
                    self.onContinue(true)
                } else {
                    self.showDeniedMessage = true
                    self.authorizationStatus = .denied
                }
            }
        }
    }
}

#Preview {
    NotificationsStep(onContinue: { _ in })
        .frame(width: 500, height: 340)
}
