//
//  AppDelegate.swift
//  Your Turn
//
//  Created by Claude on 1/20/26.
//

import AppKit
import SwiftUI
import UserNotifications

/// Application delegate handling notification lifecycle, presentation, and window management.
/// Menu bar apps should create windows programmatically, not via Window scenes.
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, UNUserNotificationCenterDelegate {

    private var setupWindow: NSWindow?
    private var settingsWindow: NSWindow?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set notification delegate early, before any notifications are posted
        UNUserNotificationCenter.current().delegate = self

        // Listen for window open requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSetupWindow),
            name: .openSetup,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettingsWindow),
            name: .openSettings,
            object: nil
        )

        // Open setup window on first launch
        if !UserDefaults.standard.bool(forKey: "setupComplete") {
            openSetupWindow()
        }
    }

    // MARK: - Window Management

    @objc private func openSetupWindow() {
        if setupWindow == nil {
            let contentView = SetupWizardView(onComplete: { [weak self] in
                UserDefaults.standard.set(true, forKey: "setupComplete")
                self?.setupWindow?.close()
                self?.setupWindow = nil
                NSApp.setActivationPolicy(.accessory)
            })

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.contentView = NSHostingView(rootView: contentView)
            window.center()
            window.isReleasedWhenClosed = false
            setupWindow = window
        }

        NSApp.setActivationPolicy(.regular)
        setupWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettingsWindow() {
        if settingsWindow == nil {
            let contentView = SettingsView(socketServer: SocketServer.shared)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 500),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Your Turn Settings"
            window.contentView = NSHostingView(rootView: contentView)
            window.center()
            window.isReleasedWhenClosed = false
            window.delegate = self
            settingsWindow = window
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Return to accessory mode when settings window closes
        if (notification.object as? NSWindow) == settingsWindow {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clear all notifications when app quits
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification is about to be presented while app is in foreground.
    /// Menu bar apps are always considered "in foreground", so this is essential.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner, add to Notification Center list, and play sound
        // .alert is deprecated in macOS 11+, use .banner and .list instead
        completionHandler([.banner, .list, .sound])
    }

    /// Called when user interacts with a notification (click or action).
    /// Routes to appropriate terminal controller via TerminalRegistry.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let termProgram = userInfo["termProgram"] as? String
        let termSessionId = userInfo["termSessionId"] as? String

        // Route to appropriate controller via registry
        if let controller = TerminalRegistry.shared.controller(for: termProgram) {
            Task { @MainActor in
                controller.activate(sessionId: termSessionId)
            }
        }
        // Silent no-op for unknown terminals (no controller found)

        completionHandler()
    }
}
