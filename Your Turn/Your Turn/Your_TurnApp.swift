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

struct WindowCoordinator: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "settings")
            }
            .onReceive(NotificationCenter.default.publisher(for: .openSetup)) { _ in
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "setup")
            }
    }
}

/// Menu shown before setup is complete
struct SetupPendingMenu: View {
    var body: some View {
        WindowCoordinator()

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
        WindowCoordinator()
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
    @StateObject private var socketServer = SocketServer()
    @AppStorage("setupComplete") private var setupComplete = false

    var body: some Scene {
        // Setup window (opens on first launch)
        Window("Your Turn Setup", id: "setup") {
            SetupWizardView(onComplete: {
                setupComplete = true
                NSApp.keyWindow?.close()
                // Return to accessory mode after setup
                NSApp.setActivationPolicy(.accessory)
            })
            .onAppear {
                // If setup is already complete (window restored by macOS), close immediately
                if setupComplete {
                    DispatchQueue.main.async {
                        NSApp.keyWindow?.close()
                        NSApp.setActivationPolicy(.accessory)
                    }
                    return
                }
                // Ensure we're in regular mode while setup is shown
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)

        // Menu bar (gated content based on setup state)
        MenuBarExtra("Your Turn", systemImage: "bubble.left") {
            if setupComplete {
                MenuBarContentView(socketServer: socketServer)
            } else {
                SetupPendingMenu()
            }
        }

        // Settings window
        Window("Your Turn Settings", id: "settings") {
            SettingsView()
                .onDisappear {
                    NSApp.setActivationPolicy(.accessory)
                }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    init() {
        // Open setup window on first launch
        if !UserDefaults.standard.bool(forKey: "setupComplete") {
            // Post notification after a brief delay to allow window scene to register
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .openSetup, object: nil)
            }
        }
    }
}
