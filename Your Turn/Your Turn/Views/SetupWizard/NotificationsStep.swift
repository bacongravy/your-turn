//
//  NotificationsStep.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import SwiftUI
import UserNotifications

/// Notifications permission step (Step 3) - request notification access
struct NotificationsStep: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isRequesting = false
    @State private var authorizationStatus: UNAuthorizationStatus?
    @State private var showDeniedMessage = false

    /// Publisher for app activation (works with programmatic NSWindow)
    private let appDidBecomeActive = NotificationCenter.default.publisher(
        for: NSApplication.didBecomeActiveNotification
    )

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Title
            Text("Enable Notifications")
                .font(.title)
                .fontWeight(.bold)

            // Explanation
            Text("Your Turn uses macOS notifications to alert you when Claude needs attention.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Status/action area - fixed height to prevent layout jumps
            Group {
                if authorizationStatus == .authorized {
                    // Already authorized
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Notifications enabled")
                            .foregroundStyle(.secondary)
                    }
                    .font(.body)
                } else if showDeniedMessage {
                    // Denied - show instructions
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
                    }
                } else {
                    // Initial state
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
            .frame(minHeight: 100)

            Spacer()

            // Navigation
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
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .onAppear {
            checkCurrentStatus()
        }
        .onReceive(appDidBecomeActive) { _ in
            // Re-check when returning from System Settings
            checkCurrentStatus()
        }
    }

    private func checkCurrentStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                authorizationStatus = settings.authorizationStatus
                // Update denied message based on current status
                showDeniedMessage = settings.authorizationStatus == .denied
            }
        }
    }

    private func requestNotifications() {
        isRequesting = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                isRequesting = false
                if granted {
                    authorizationStatus = .authorized
                    // Auto-advance on success
                    onContinue()
                } else {
                    showDeniedMessage = true
                    authorizationStatus = .denied
                }
            }
        }
    }
}

#Preview {
    NotificationsStep(onContinue: {}, onBack: {})
        .frame(width: 500, height: 350)
}
