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
    /// Session info is stored in userInfo for future iTerm focusing (Phase 5).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Extract session info from userInfo for future use
        // Phase 5 will implement iTerm focusing based on this data
        let userInfo = response.notification.request.content.userInfo
        _ = userInfo["sessionId"] as? String
        _ = userInfo["cwd"] as? String
        _ = userInfo["termSessionId"] as? String

        // For now, just acknowledge the response
        completionHandler()
    }
}
