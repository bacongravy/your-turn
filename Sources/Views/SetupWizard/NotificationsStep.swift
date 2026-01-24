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
    let onBack: () -> Void

    @State private var isRequesting = false
    @State private var authorizationStatus: UNAuthorizationStatus?
    @State private var showDeniedMessage = false

    private let appDidBecomeActive = NotificationCenter.default.publisher(
        for: NSApplication.didBecomeActiveNotification
    )

    var body: some View {
        WizardStepLayout(
            title: "Enable Notifications",
            subtitle: "Your Turn uses macOS notifications to alert you when Claude needs your attention.",
            onBack: onBack,
            onContinue: { onContinue(authorizationStatus == .authorized) },
            continueLabel: continueButtonLabel
        ) {
            VStack(spacing: 12) {
                if authorizationStatus == .authorized {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Notifications enabled")
                            .foregroundStyle(.secondary)
                    }
                    .font(.body)
                } else if showDeniedMessage {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Notifications are disabled")
                        }

                        Button("Open Notification Settings") {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.bordered)

                        Text("You can continue without notifications, but you won't receive alerts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Button {
                        requestNotifications()
                    } label: {
                        if isRequesting {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal, 8)
                        } else {
                            Text("Enable Notifications")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isRequesting)
                }
            }
        }
        .onAppear {
            checkCurrentStatus()
        }
        .onReceive(appDidBecomeActive) { _ in
            checkCurrentStatus()
        }
    }

    private var continueButtonLabel: String {
        if authorizationStatus == .authorized {
            return "Continue"
        } else if showDeniedMessage {
            return "Skip"
        } else {
            return "Continue"
        }
    }

    private func checkCurrentStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                authorizationStatus = settings.authorizationStatus
                showDeniedMessage = settings.authorizationStatus == .denied
            }
        }
    }

    private func requestNotifications() {
        isRequesting = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                isRequesting = false
                if granted {
                    authorizationStatus = .authorized
                    onContinue(true)
                } else {
                    showDeniedMessage = true
                    authorizationStatus = .denied
                }
            }
        }
    }
}

#Preview {
    NotificationsStep(onContinue: { _ in }, onBack: {})
        .frame(width: 500, height: 340)
}
