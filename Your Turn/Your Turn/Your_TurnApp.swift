//
//  Your_TurnApp.swift
//  Your Turn
//
//  Created by David Kramer on 1/19/26.
//

import SwiftUI

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}

struct SettingsCoordinator: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            }
    }
}

@main
struct Your_TurnApp: App {
    var body: some Scene {
        MenuBarExtra("Your Turn", systemImage: "bubble.left") {
            SettingsCoordinator()

            Button("Settings...") {
                NotificationCenter.default.post(name: .openSettings, object: nil)
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }

        Window("Your Turn Settings", id: "settings") {
            SettingsView()
                .onDisappear {
                    NSApp.setActivationPolicy(.accessory)
                }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
