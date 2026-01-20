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

/// Wrapper view to handle socket server lifecycle and error alerts
struct MenuBarContentView: View {
    @ObservedObject var socketServer: SocketServer
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        SettingsCoordinator()

        Button("Settings...") {
            NotificationCenter.default.post(name: .openSettings, object: nil)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") {
            socketServer.stop()
            NSApplication.shared.terminate(nil)
        }
        .onAppear {
            socketServer.start()
        }
        .onChange(of: socketServer.error != nil) { _, hasError in
            if hasError, let error = socketServer.error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
        .alert("Socket Server Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to start socket server: \(errorMessage)")
        }
    }
}

@main
struct Your_TurnApp: App {
    @StateObject private var socketServer = SocketServer()

    var body: some Scene {
        MenuBarExtra("Your Turn", systemImage: "bubble.left") {
            MenuBarContentView(socketServer: socketServer)
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
