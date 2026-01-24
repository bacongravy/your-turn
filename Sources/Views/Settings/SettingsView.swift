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
    case events
}

struct SettingsView: View {
    var socketServer: SocketServer = .shared
    @State private var selectedTab = SettingTab.general

    var body: some View {
        Group {
            Picker("", selection: $selectedTab) {
                Text("General")
                    .tag(SettingTab.general)
                Text("Notifications")
                    .tag(SettingTab.notifications)
                Text("Events")
                    .tag(SettingTab.events)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal)
            .padding(.top, 12)

            Group {
                switch selectedTab {
                case .general:
                    Form {
                        HealthStatusSection(socketServer: socketServer)
                        GeneralSection()
                    }
                case .notifications:
                    Form {
                        NotificationSection()
                    }
                case .events:
                    Form {
                        EventsSection()
                    }
                }
            }
            .padding(.top, -8)
        }
        .formStyle(.grouped)
        .frame(width: 450)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            // Hidden buttons for keyboard shortcuts
            Group {
                Button("") { selectedTab = .general }
                    .keyboardShortcut("1", modifiers: .command)
                Button("") { selectedTab = .notifications }
                    .keyboardShortcut("2", modifiers: .command)
                Button("") { selectedTab = .events }
                    .keyboardShortcut("3", modifiers: .command)
            }
            .opacity(0)
            .allowsHitTesting(false)
        }
    }
}
