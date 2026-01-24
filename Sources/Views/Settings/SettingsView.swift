//
//  SettingsView.swift
//  Your Turn
//
//  Created by Your Turn on 2026-01-20.
//

import SwiftUI

enum SettingTab: Int, Hashable {
    case general
    case notifications
}

struct SettingsView: View {
    var socketServer: SocketServer = .shared
    @State private var selectedTab = SettingTab.general

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("General", systemImage: "gear", value: SettingTab.general) {
                GeneralTabContent(socketServer: socketServer)
            }
            Tab("Notifications", systemImage: "bell", value: SettingTab.notifications) {
                NotificationsTabContent()
            }
        }
        .frame(width: 450)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            // Hidden buttons for keyboard shortcuts
            Group {
                Button("") { selectedTab = .general }
                    .keyboardShortcut("1", modifiers: .command)
                Button("") { selectedTab = .notifications }
                    .keyboardShortcut("2", modifiers: .command)
            }
            .opacity(0)
            .allowsHitTesting(false)
        }
    }
}
