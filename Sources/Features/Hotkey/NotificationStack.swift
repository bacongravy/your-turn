//
//  NotificationStack.swift
//  Your Turn
//
//  Created by Claude on 2/15/26.
//

import Combine
import Foundation
import UserNotifications

/// LIFO stack of pending notification entries. Each hotkey press pops the most recent entry.
/// Entries are added when notifications are posted and removed when clicked or hotkey-activated.
@MainActor
final class NotificationStack: ObservableObject {
    static let shared = NotificationStack()

    struct Entry {
        let sessionId: String
        let termProgram: String?
        let termSessionId: String?
        let tty: String?
        let notificationIdentifier: String
        let timestamp: Date
    }

    @Published private(set) var entries: [Entry] = []

    private init() {}

    var isEmpty: Bool { entries.isEmpty }
    var count: Int { entries.count }

    /// Push a new entry. If an entry with the same notificationIdentifier exists, replace it.
    func push(
        sessionId: String,
        termProgram: String?,
        termSessionId: String?,
        tty: String?,
        notificationIdentifier: String
    ) {
        // Remove existing entry with same identifier (notification replacement)
        entries.removeAll { $0.notificationIdentifier == notificationIdentifier }

        entries.append(Entry(
            sessionId: sessionId,
            termProgram: termProgram,
            termSessionId: termSessionId,
            tty: tty,
            notificationIdentifier: notificationIdentifier,
            timestamp: Date()
        ))
    }

    /// Remove and return the most recent entry.
    func popLatest() -> Entry? {
        guard !entries.isEmpty else { return nil }
        return entries.removeLast()
    }

    /// Remove entry by notification identifier (called when user clicks a notification).
    func remove(identifier: String) {
        entries.removeAll { $0.notificationIdentifier == identifier }
    }

    /// Remove entries whose notifications are no longer in the delivered list.
    /// Handles swipe-to-dismiss since macOS has no delegate callback for dismissed notifications.
    func pruneToDelivered() async {
        let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
        let deliveredIds = Set(delivered.map(\.request.identifier))
        entries.removeAll { !deliveredIds.contains($0.notificationIdentifier) }
    }
}
