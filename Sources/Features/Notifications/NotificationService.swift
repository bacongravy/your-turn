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
    private let logger = Logger(category: "NotificationService")

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
        // === SHARED CONDITIONS (apply to both notification and sound) ===

        // Check if this event type is enabled
        guard isEventTypeEnabled(for: event) else {
            let key = eventTypeKey(for: event) ?? "unknown"
            logger.debug("Event suppressed: \(key) is disabled or unknown")
            return
        }

        // Check smart suppression (user focused on terminal)
        guard !shouldSmartSuppress(event) else {
            return  // Logging handled in helper
        }

        // === INDEPENDENT ACTIONS ===

        // Play sound (SoundPlayer checks notify.soundEnabled internally)
        SoundPlayer.shared.playNotificationSound()

        // Post notification if enabled
        let notificationsEnabled = UserDefaults.standard.bool(
            forKey: "notify.enabled",
            default: true
        )

        if notificationsEnabled {
            Task {
                await requestAuthorizationIfNeeded()
                await postNotification(for: event)
            }
        }
    }

    // MARK: - Event Filtering

    private func isEventTypeEnabled(for event: HookEvent) -> Bool {
        guard let key = eventTypeKey(for: event) else {
            return false  // Unknown event types are disabled
        }

        // Default values: taskComplete/inputNeeded enabled
        let defaultValue: Bool
        switch key {
        case "notify.taskComplete", "notify.inputNeeded":
            defaultValue = true
        default:
            defaultValue = true
        }

        return UserDefaults.standard.bool(forKey: key, default: defaultValue)
    }

    private func shouldSmartSuppress(_ event: HookEvent) -> Bool {
        if ITerm2.shouldSuppressNotification(for: event) {
            logger.debug("Event suppressed: user focused on iTerm session \(event.termSessionId ?? "unknown")")
            return true
        }

        if TerminalApp.shouldSuppressNotification(for: event) {
            logger.debug("Event suppressed: user focused on Terminal.app tab \(event.tty ?? "unknown")")
            return true
        }

        return false
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
        let projectPath = event.projectDir ?? event.cwd
        let projectName = URL(fileURLWithPath: projectPath).lastPathComponent
        content.title = "It's your turn!"
        content.subtitle = "Project: \(projectName)"
        content.body = bodyMessage(for: event)
        content.interruptionLevel = .active

        // Store session info for terminal focusing
        content.userInfo = [
            "sessionId": event.sessionId,
            "cwd": event.cwd,
            "termSessionId": event.termSessionId ?? "",
            "termProgram": event.termProgram ?? "",
            "tty": event.tty ?? ""
        ]

        // Use session-based identifier for notification replacement
        let identifier = "session-\(event.sessionId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.info("Posted notification for session \(event.sessionId): \(content.body)")
        } catch {
            logger.error("Failed to post notification: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers
    private func bodyMessage(for event: HookEvent) -> String {
        switch event.hookEventName {
        case "Notification":
            switch event.notificationType {
            case "permission_prompt":
                return "Claude Code is asking for permission"
            case "elicitation_dialog":
                return "Claude Code needs input for a tool"
            case "idle_prompt":
                return "Claude Code has been waiting for input"
            default:
                return "Claude Code needs your attention"
            }
        case "Stop":
            return "Claude Code has finished"
        default:
            return "Claude Code needs your attention"
        }
    }

    private func eventTypeKey(for event: HookEvent) -> String? {
        switch event.hookEventName {
        case "Notification":
            switch event.notificationType {
            case "permission_prompt", "elicitation_dialog":
                return "notify.inputNeeded"
            // idle_prompt appears broken in Claude Code (GitHub issue #8320 closed as "not planned")
            default:
                return nil  // Unknown notification types are ignored
            }
        case "Stop":
            return "notify.taskComplete"
        default:
            return nil  // Unknown hook events are ignored
        }
    }

}
