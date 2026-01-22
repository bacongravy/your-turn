//
//  NotificationService.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import AppKit
import Combine
import Foundation
import UserNotifications
import os.log

/// Service that observes socket events and posts macOS notifications.
/// Handles event filtering, smart suppression, and session-based notification replacement.
@MainActor
class NotificationService: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "net.bacongravy.Your-Turn", category: "NotificationService")

    init(socketServer: SocketServer) {
        socketServer.$lastEvent
            .compactMap { $0 }
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)

        logger.info("NotificationService initialized and subscribed to socket events")
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: HookEvent) {
        let defaults = UserDefaults.standard

        // Check if notifications are globally enabled (default: true)
        let notificationsEnabled = defaults.object(forKey: "notify.enabled") != nil
            ? defaults.bool(forKey: "notify.enabled")
            : true

        guard notificationsEnabled else {
            logger.debug("Notification suppressed: notifications globally disabled")
            return
        }

        // Check if notification is enabled for this event type
        let key = eventTypeKey(for: event)

        // Default values match EventsSection: permission/inputNeeded enabled, taskComplete/error disabled
        let defaultValue: Bool
        switch key {
        case "notify.permission", "notify.inputNeeded":
            defaultValue = true
        case "notify.taskComplete", "notify.error":
            defaultValue = false
        default:
            defaultValue = true
        }

        // Note: UserDefaults.bool(forKey:) returns false for non-existent keys,
        // so we need to check if the key exists first
        let isEnabled: Bool
        if defaults.object(forKey: key) != nil {
            isEnabled = defaults.bool(forKey: key)
        } else {
            isEnabled = defaultValue
        }

        guard isEnabled else {
            logger.debug("Notification suppressed: \(key) is disabled")
            return
        }

        // Check smart suppression
        if shouldSuppress(event: event) {
            logger.debug("Notification suppressed: user is focused on iTerm session \(event.termSessionId ?? "unknown")")
            return
        }

        // Request authorization if needed, then post notification
        Task {
            await requestAuthorizationIfNeeded()
            await postNotification(for: event)
        }
    }

    // MARK: - Authorization

    private func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        guard settings.authorizationStatus == .notDetermined else {
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            logger.info("Notification authorization \(granted ? "granted" : "denied")")
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
        }
    }

    // MARK: - Post Notification

    private func postNotification(for event: HookEvent) async {
        let content = UNMutableNotificationContent()
        content.title = "Your Turn"
        content.body = bodyMessage(for: event)
        content.interruptionLevel = .active

        // Store session info for iTerm focusing
        content.userInfo = [
            "sessionId": event.sessionId,
            "cwd": event.cwd,
            "termSessionId": event.termSessionId ?? "",
            "termProgram": event.termProgram ?? ""
        ]

        // Use session-based identifier for notification replacement
        let identifier = "session-\(event.sessionId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("Posted notification for session \(event.sessionId): \(content.body)")

            // Play sound via app (with repeat support)
            SoundPlayer.shared.playNotificationSound()
        } catch {
            logger.error("Failed to post notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func bodyMessage(for event: HookEvent) -> String {
        let projectName = URL(fileURLWithPath: event.cwd).lastPathComponent

        switch event.hookEventName {
        case "notification":
            // Check notification type
            if event.notificationType == "permission" ||
               (event.message?.lowercased().contains("permission") ?? false) {
                return "Waiting for your permission in \(projectName)"
            } else if event.notificationType == "error" {
                if let message = event.message, !message.isEmpty {
                    // Truncate long error messages
                    let briefError = message.prefix(50)
                    return "Something went wrong in \(projectName): \(briefError)"
                }
                return "Something went wrong in \(projectName)"
            } else {
                // Input needed
                return "Waiting for your next instruction in \(projectName)"
            }
        case "stop":
            return "Task complete in \(projectName)"
        default:
            return "Claude needs attention in \(projectName)"
        }
    }

    private func eventTypeKey(for event: HookEvent) -> String {
        switch event.hookEventName {
        case "notification":
            switch event.notificationType {
            case "permission":
                return "notify.permission"
            case "error":
                return "notify.error"
            default:
                return "notify.inputNeeded"
            }
        case "stop":
            return "notify.taskComplete"
        default:
            return "notify.inputNeeded"
        }
    }

    private func shouldSuppress(event: HookEvent) -> Bool {
        // If no terminal session ID, can't suppress
        guard let termSessionId = event.termSessionId, !termSessionId.isEmpty else {
            return false
        }

        // Check if iTerm2 is frontmost app
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              frontmostApp.bundleIdentifier == "com.googlecode.iterm2" else {
            return false
        }

        // Get current iTerm session via AppleScript
        guard let currentSessionId = getCurrentiTermSessionId() else {
            return false
        }

        // Suppress only if user is focused on the same session
        return termSessionId == currentSessionId
    }

    private func getCurrentiTermSessionId() -> String? {
        let script = """
            tell application "iTerm2"
                tell current session of current window
                    return unique id
                end tell
            end tell
            """

        guard let appleScript = NSAppleScript(source: script) else {
            return nil
        }

        var errorInfo: NSDictionary?
        let result = appleScript.executeAndReturnError(&errorInfo)

        if errorInfo != nil {
            // iTerm not running, no window, or other error - fail gracefully
            return nil
        }

        return result.stringValue
    }
}
