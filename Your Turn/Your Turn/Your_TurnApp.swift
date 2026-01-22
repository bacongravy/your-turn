//
//  Your_TurnApp.swift
//  Your Turn
//
//  Created by David Kramer on 1/19/26.
//

import SwiftUI
import UserNotifications

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
    static let openSetup = Notification.Name("openSetup")
}

/// Menu shown before setup is complete
struct SetupPendingMenu: View {
    var body: some View {
        Text("Setup required before use")
            .foregroundStyle(.secondary)
            .font(.caption)

        Button("Complete Setup...") {
            NotificationCenter.default.post(name: .openSetup, object: nil)
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}

/// Wrapper view to handle socket server lifecycle and error alerts
struct MenuBarContentView: View {
    @ObservedObject var socketServer: SocketServer
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var notificationService: NotificationService?

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task {
                if notificationService == nil {
                    notificationService = NotificationService(socketServer: socketServer)
                }
            }

        Button("Settings...") {
            NotificationCenter.default.post(name: .openSettings, object: nil)
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit") {
            socketServer.stop()
            NSApplication.shared.terminate(nil)
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
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var socketServer: SocketServer
    @AppStorage("setupComplete") private var setupComplete = false

    init() {
        // Create socket server and set shared reference immediately
        // This ensures it's available before any views try to access it
        let server = SocketServer()
        _socketServer = StateObject(wrappedValue: server)
        SocketServer.shared = server
    }

    var body: some Scene {
        // Menu bar only - windows are created programmatically by AppDelegate
        MenuBarExtra("Your Turn", image: "MenuBarIcon") {
            Group {
                if setupComplete {
                    MenuBarContentView(socketServer: socketServer)
                } else {
                    SetupPendingMenu()
                }
            }
        }
    }
}
