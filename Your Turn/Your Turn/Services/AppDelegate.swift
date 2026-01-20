//
//  AppDelegate.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import AppKit
import UserNotifications

/// Application delegate handling notification lifecycle and presentation.
/// Must be set as UNUserNotificationCenter delegate before any notifications are posted.
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set notification delegate early, before any notifications are posted
        UNUserNotificationCenter.current().delegate = self
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clear all notifications when app quits
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification is about to be presented while app is in foreground.
    /// Menu bar apps are always considered "in foreground", so this is essential.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, add to Notification Center list, and play sound
        // .alert is deprecated in macOS 11+, use .banner and .list instead
        completionHandler([.banner, .list, .sound])
    }

    /// Called when user interacts with a notification (click or action).
    /// Dispatches to ITermController to focus the terminal session.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        let termProgram = userInfo["termProgram"] as? String ?? ""
        let termSessionId = userInfo["termSessionId"] as? String ?? ""

        // Only attempt iTerm focus if notification came from iTerm
        if termProgram.lowercased().contains("iterm") {
            if !termSessionId.isEmpty {
                Task { @MainActor in
                    ITermController.shared.focusSession(termSessionId: termSessionId)
                }
            } else {
                // Fallback: bring iTerm to front without specific session
                Task { @MainActor in
                    ITermController.shared.activateiTerm()
                }
            }
        }
        // Silent no-op for non-iTerm terminals

        completionHandler()
    }
}
