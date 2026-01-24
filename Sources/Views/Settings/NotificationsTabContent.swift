//
//  NotificationsTabContent.swift
//  Your Turn
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

/// Content wrapper for the Notifications tab in Settings
/// Contains: Sound/notification settings and Event toggles
struct NotificationsTabContent: View {
    var body: some View {
        Form {
            NotificationSection()
            EventsSection()
        }
        .formStyle(.grouped)
        .padding(.top, -20)
    }
}
